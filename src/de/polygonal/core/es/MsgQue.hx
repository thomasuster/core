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

import de.polygonal.core.util.Assert;
import haxe.ds.Vector;

@:access(de.polygonal.core.es.Entity)
@:access(de.polygonal.core.es.EntitySystem)
class MsgQue
{
	static var MAX_SIZE = 1 << 15; //1024KiB for ~32K messages, (alchemy ~700KiB)
	
	var _que:Vector<Int>;
	var _capacity:Int;
	var _size:Int;
	var _front:Int;
	
	var _nextLocker:Int;
	var _currLocker:Int;
	var _locker:Array<Dynamic>;
	
	public function new()
	{
		_capacity = MAX_SIZE << 3;
		_size = 0;
		_front = 0;
		
		#if alchemy
		//4 shorts and 4 ints = 16 bytes per message: 512KiB @ 0x8000
		_que = new de.polygonal.ds.mem.ByteMemory(_capacity * 16, "msg_que_buffer");
		#else
		//768KiB @ 0x8000
		_que = new Vector<Int>(_capacity);
		#end
		
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
	
	public function enqueue(sender:Entity, recipient:Entity, type:Int, remaining:Int)
	{
		D.assert(sender != null);
		D.assert(recipient != null);
		D.assert(type >= 0 && type <= 0xffff);
		D.assert(_size < MAX_SIZE, "message queue exhausted");
		
		var i = (_front + (_size << 3)) % _capacity;
		_size++;
		
		if (recipient.getFlags() & (Entity.BIT_GHOST | Entity.BIT_SKIP_MSG) > 0)
		{
			_que[i] = -1;
			return;
		}
		
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
		var a = EntitySystem._freeList;
		
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
		
		while (_size > 0)
		{
			//while there are buffered messages
			//process k buffered messages
			k = _size;
			i = k;
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
				
				if (sender.id.inner != senderInner)
				{
					//skip message if sender was removed+replaced
					f = (f + 8) % c;
					i--;
					continue;
				}
				
				if (recipient.id.inner != recipientInner)
				{
					//skip message if recipient was removed+replaced
					f = (f + 8) % c;
					i--;
					continue;
				}
				
				//dequeue
				f = (f + 8) % c;
				i--;
				
				//notify recipient
				
				#if verbose
				var data = _locker[_currLocker] != null ? ' ${_locker[_currLocker]}' : "";
				
				var senderId = sender.name == null ? Std.string(sender.id) : sender.name;
				var recipientId = recipient.name == null ? Std.string(recipient.id) : recipient.name;
				L.d('message from "$senderId" => "$recipientId": $type$data');
				#end
				
				recipient.onMsg(type, sender);
				if (recipient.getFlags() & Entity.BIT_STOP_PROPAGATION > 0)
				{
					//recipient stopped notification;
					//reset flag and skip remaining messages in current batch
					recipient.clrFlags(Entity.BIT_STOP_PROPAGATION);
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