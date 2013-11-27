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
	
	inline static var MSG_SIZE =
	#if alchemy
	//sender+recipient inner: 2*4 bytes
	//sender+recipient index: 2*2 bytes
	//type, skip count, locker index: 3*2 bytes
	18; //bytes
	#else
	7; //32bit ints
	#end
	
	var _capacity:Int;
	
	var _que:
	#if alchemy
	de.polygonal.ds.mem.ByteMemory;
	#else
	Vector<Int>;
	#end
	
	var _size:Int;
	var _front:Int;
	
	var _nextLocker:Int;
	var _currLocker:Int;
	var _locker:Array<Dynamic>;
	
	public function new()
	{
		_capacity = MAX_SIZE * MSG_SIZE;
		_que =
		#if alchemy
		//id.inner for sender: 4 bytes
		//id.inner for recipient: 4 bytes
		//id.index for sender: 2 bytes
		//id.index for recipient: 2 bytes
		//type: 2 bytes
		//remaining: 2 bytes
		//locker index: 2 bytes
		new de.polygonal.ds.mem.ByteMemory(_capacity);
		#else
		new Vector<Int>(_capacity);
		#end
		
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
		
		var i = (_front + (_size * MSG_SIZE)) % _capacity;
		_size++;
		
		if (recipient._flags & (E.BIT_GHOST | E.BIT_SKIP_MSG | E.BIT_MARK_FREE | E.BIT_MARK_REMOVE) > 0)
		{
			//enqueue message even if recipient doesn't want it;
			//this is required for properly stopping a message propagation (when an entity calls stop())
			#if alchemy
			flash.Memory.setI32(i, -1);
			#else
			_que[i] = -1;
			#end
			return;
		}
		
		#if (verbose == "extra")
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
		
		#if alchemy
		var addr = _que.getAddr(i);
		flash.Memory.setI32(addr     , senderId.inner);
		flash.Memory.setI32(addr +  4, recipientId.inner);
		flash.Memory.setI16(addr +  8, senderId.index);
		flash.Memory.setI16(addr + 10, recipientId.index);
		flash.Memory.setI16(addr + 12, type);
		flash.Memory.setI16(addr + 14, remaining);
		flash.Memory.setI16(addr + 16, _nextLocker);
		#else
		_que[i    ] = senderId.inner;
		_que[i + 1] = recipientId.inner;
		_que[i + 2] = senderId.index;
		_que[i + 3] = recipientId.index;
		_que[i + 4] = type;
		_que[i + 5] = remaining;
		_que[i + 6] = _nextLocker;
		#end
		
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
		var sender:Entity;
		var recipient:Entity;
		
		var q = _que;
		var c = _capacity;
		var f = _front;
		var k = 0;
		var i = 0;
		var iter = 0;
		
		#if verbose
		var numSkippedMessages = 0;
		var numDispatchedMessages = 0;
		#end
		
		while (_size > 0)
		{
			//while there are buffered messages
			//process k buffered messages
			k = _size;
			i = k;
			
			#if (verbose == "extra")
			L.d('iter $iter: dispatching $k messages ...', "es");
			iter++;
			#end
			
			while (i > 0)
			{
				#if alchemy
				var addr       = _que.getAddr(f);
				senderInner    = flash.Memory.getI32(addr);
				recipientInner = flash.Memory.getI32(addr  +  4);
				senderIndex    = flash.Memory.getUI16(addr +  8);
				recipientIndex = flash.Memory.getUI16(addr + 10);
				type           = flash.Memory.getUI16(addr + 12);
				skipCount      = flash.Memory.getUI16(addr + 14);
				_currLocker    = flash.Memory.getUI16(addr + 16);
				#else
				senderInner    = q[f    ];
				recipientInner = q[f + 1];
				senderIndex    = q[f + 2];
				recipientIndex = q[f + 3];
				type           = q[f + 4];
				skipCount      = q[f + 5];
				_currLocker    = q[f + 6];
				#end
				
				//ignore message?
				if (senderInner == -1)
				{
					#if verbose
					numSkippedMessages++;
					#end
					
					f = (f + MSG_SIZE) % c;
					i--;
					continue;
				}
				
				sender = a[senderIndex];
				D.assert(sender != null);
				
				recipient = a[recipientIndex];
				D.assert(recipient != null);
				
				//dequeue
				f = (f + MSG_SIZE) % c;
				i--;
				
				#if (verbose == "extra")
				var data = _locker[_currLocker] != null ? '${_locker[_currLocker]}' : "";
				var senderId = sender.name == null ? Std.string(sender.id) : sender.name;
				var recipientId = recipient.name == null ? Std.string(recipient.id) : recipient.name;
				
				if (senderId.length > 30) senderId = StringUtil.ellipsis(senderId, 30, 1, true);
				if (recipientId.length > 30) recipientId = StringUtil.ellipsis(recipientId, 30, 1, true);
				
				var msgName = Msg.name(type);
				if (msgName.length > 20) msgName = StringUtil.ellipsis(msgName, 20, 1, true);
				
				L.d(Printf.format('message %30s -> %-30s: %-20s $data', [senderId, recipientId, msgName]), "es");
				#end
				
				//notify recipient
				if (recipient._flags & (E.BIT_GHOST | E.BIT_SKIP_MSG | E.BIT_MARK_FREE | E.BIT_MARK_REMOVE) == 0)
				{
					recipient.onMsg(type, sender);
					
					#if verbose
					numDispatchedMessages++;
					#end
				}
				else
				{
					#if verbose
					numSkippedMessages++;
					#end
				}
				
				if (recipient._flags & E.BIT_STOP_PROPAGATION > 0)
				{
					//recipient stopped notification;
					//reset flag and skip remaining messages in current batch
					recipient._flags &= ~E.BIT_STOP_PROPAGATION;
					f += (skipCount * MSG_SIZE) % c;
					i -= skipCount;
				}
			}
			_size -= k;
			_front = f;
		}
		
		#if verbose
		L.d('dispatched $numDispatchedMessages messages (skipped: $numSkippedMessages)');
		#end
		
		//empty locker
		for (i in 0..._nextLocker)
			_locker[i] = null;
		_nextLocker = 0;
		_currLocker = -1;
	}
}