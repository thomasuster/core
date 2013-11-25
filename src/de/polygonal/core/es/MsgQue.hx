/*
 *                            _/                                                    _/
 *       _/_/_/      _/_/    _/  _/    _/    _/_/_/    _/_/    _/_/_/      _/_/_/  _/
 *      _/    _/  _/    _/  _/  _/    _/  _/    _/  _/    _/  _/    _/  _/    _/  _/
 *     _/    _/  _/    _/  _/  _/    _/  _/    _/  _/    _/  _/    _/  _/    _/  _/
 *    _/_/_/      _/_/    _/    _/_/_/    _/_/_/    _/_/    _/    _/    _/_/_/  _/
 *   _/                            _/        _/
 *  _/                        _/_/      _/_/
 *
 * POLYGONAL - A HAXE LIBRARY FOR GAME DEVELOPERS
 * Copyright (c) 2013 Michael Baczynski, http://www.polygonal.de
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 * LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
 * OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
 * WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */
package de.polygonal.core.es;

import de.polygonal.core.fmt.StringUtil;
import de.polygonal.core.util.Assert;
import de.polygonal.Printf;
import haxe.ds.Vector;

import de.polygonal.core.es.Entity in E;
import de.polygonal.core.es.EntitySystem in ES;

@:access(de.polygonal.core.es.Entity)
@:access(de.polygonal.core.es.EntitySystem)
class MsgQue
{
	static var MAX_SIZE = 1 << 15;
	
	var _capacity:Int;
	var _que:Vector<Int>;
	var _size:Int;
	var _front:Int;
	
	var _nextLocker:Int;
	var _currLocker:Int;
	var _locker:Array<Dynamic>;
	
	public function new()
	{
		_capacity = MAX_SIZE << 3;
		_que = new Vector<Int>(_capacity);
		_size = 0;
		_front = 0;
		
		_nextLocker = 0;
		_currLocker = -1;
		_locker = new Array<Dynamic>();
	}
	
	public function putData(o:Dynamic)
	{
		D.assert(_currLocker != -1);
		_locker[_currLocker] = o;
	}
	
	public function getData():Dynamic
	{
		D.assert(_currLocker != -1);
		return _locker[_currLocker];
	}
	
	public function enqueue(sender:E, recipient:E, type:Int, remaining:Int)
	{
		D.assert(sender != null);
		D.assert(recipient != null);
		D.assert(type >= 0 && type <= 0xffff);
		D.assert(_size < MAX_SIZE, "message queue exhausted");
		
		var i = (_front + (_size << 3)) % _capacity;
		_size++;
		
		if (recipient._flags & (E.BIT_GHOST | E.BIT_SKIP_MSG | E.BIT_MARK_FREE | E.BIT_MARK_REMOVE) > 0)
		{
			//enqueue message even if recipient doesn't want it;
			//this is required for properly stopping a message propagation (when an entity calls stop())
			_que[i] = -1;
			return;
		}
		
		#if verbose
		var senderId = sender.name == null ? Std.string(sender.id) : sender.name;
		var recipientId = recipient.name == null ? Std.string(recipient.id) : recipient.name;
		
		if (senderId.length > 30) senderId = StringUtil.ellipsis(senderId, 30, 1, true);
		if (recipientId.length > 30) recipientId = StringUtil.ellipsis(recipientId, 30, 1, true);
		
		var msgName = Msg.name(type);
		if (msgName.length > 20) msgName = StringUtil.ellipsis(msgName, 20, 1, true);
		
		L.d(Printf.format('enqueue message %30s -> %-30s: %-20s (remaining: $remaining)', [senderId, recipientId, msgName]));
		#end
		
		var senderId = sender.id;
		var recipientId = recipient.id;
		
		_que[i + 0] = senderId.index;
		_que[i + 1] = recipientId.index;
		_que[i + 2] = senderId.inner;
		_que[i + 3] = recipientId.inner;
		_que[i + 4] = type;
		_que[i + 5] = remaining;
		_que[i + 6] = _nextLocker;
		
		if (remaining == 0)
		{
			//use same locker for multiple recipients
			_currLocker = _nextLocker++;
		}
	}
	
	public function dispatch()
	{
		var a = ES._freeList;
		
		var senderIndex:Int;
		var senderInner:Int;
		var recipientIndex:Int;
		var recipientInner:Int;
		var type:Int;
		var skipCount:Int;
		
		var q = _que;
		var c = _capacity;
		var f = _front;
		var k = 0;
		var i = 0;
		var iter = 0;
		
		while (_size > 0)
		{
			//while there are buffered messages
			//process k buffered messages
			k = _size;
			i = k;
			
			#if verbose
			L.d('iter $iter: dispatching $k messages ...');
			iter++;
			#end
			
			while (i > 0)
			{
				senderIndex    = q[f + 0];
				recipientIndex = q[f + 1];
				senderInner    = q[f + 2];
				recipientInner = q[f + 3];
				type           = q[f + 4];
				skipCount      = q[f + 5];
				_currLocker    = q[f + 6];
				
				//ignore message?
				if (senderIndex == -1)
				{
					f = (f + 8) % c;
					i--;
					continue;
				}
				
				var sender = a[senderIndex];
				if (sender == null)
				{
					//skip message if sender was removed
					f = (f + 8) % c;
					i--;
					continue;
				}
				
				var recipient = a[recipientIndex];
				if (recipient == null)
				{
					//skip message if recipient was removed
					f = (f + 8) % c;
					i--;
					continue;
				}
				
				if (sender.id == null || sender.id.inner != senderInner)
				{
					//skip message if sender was freed/replaced
					f = (f + 8) % c;
					i--;
					continue;
				}
				
				if (recipient.id == null || recipient.id.inner != recipientInner)
				{
					//skip message if recipient was freed/replaced
					f = (f + 8) % c;
					i--;
					continue;
				}
				
				//dequeue
				f = (f + 8) % c;
				i--;
				
				//notify recipient
				
				#if verbose
				var data = _locker[_currLocker] != null ? '${_locker[_currLocker]}' : "";
				var senderId = sender.name == null ? Std.string(sender.id) : sender.name;
				var recipientId = recipient.name == null ? Std.string(recipient.id) : recipient.name;
				
				if (senderId.length > 30) senderId = StringUtil.ellipsis(senderId, 30, 1, true);
				if (recipientId.length > 30) recipientId = StringUtil.ellipsis(recipientId, 30, 1, true);
				
				var msgName = Msg.name(type);
				if (msgName.length > 20) msgName = StringUtil.ellipsis(msgName, 20, 1, true);
				
				L.d(Printf.format('message %30s -> %-30s: %-20s $data', [senderId, recipientId, msgName]));
				#end
				
				recipient.onMsg(type, sender);
				if (recipient._flags & E.BIT_STOP_PROPAGATION > 0)
				{
					//recipient stopped notification;
					//reset flag and skip remaining messages in current batch
					recipient._flags |= ~E.BIT_STOP_PROPAGATION;
					f += (skipCount << 3) % c;
					i -= skipCount;
				}
			}
			_size -= k;
			_front = f;
		}
		
		for (i in 0..._nextLocker)
			_locker[i] = null;
		_nextLocker = 0;
		_currLocker = -1;
	}
}