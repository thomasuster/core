/*
Copyright (c) 2012-2014 Michael Baczynski, http://www.polygonal.de

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute,
sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or
substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
package de.polygonal.core.es;

import de.polygonal.core.fmt.StringUtil;
import de.polygonal.core.util.Assert;
import de.polygonal.Printf;
import haxe.ds.Vector;

import de.polygonal.core.es.Entity in E;
import de.polygonal.core.es.EntitySystem in ES;

#if alchemy
import flash.Memory in Mem;
#end

@:access(de.polygonal.core.es.Entity)
@:access(de.polygonal.core.es.EntitySystem)
class MsgQue
{
	inline static var MSG_SIZE =
	#if alchemy
	//sender+recipient inner: 2*4 bytes
	//sender+recipient index: 2*2 bytes
	//type, skip count, locker index: 3*2 bytes
	18; //#bytes
	#else
	7; //#32bit integers
	#end
	
	var mQue:
	#if alchemy
	de.polygonal.ds.mem.ByteMemory;
	#else
	Vector<Int>;
	#end
	
	var mCapacity:Int;
	var mSize:Int;
	var mFront:Int;
	
	var mNextLocker:Int;
	var mCurrLocker:Int;
	var mLocker:Array<Dynamic>;
	
	var mIsDispatching:Bool;
	
	public function new(capacity:Int)
	{
		mCapacity = capacity;
		
		mQue =
		#if alchemy
		//id.inner for sender: 4 bytes
		//id.inner for recipient: 4 bytes
		//id.index for sender: 2 bytes
		//id.index for recipient: 2 bytes
		//type: 2 bytes
		//remaining: 2 bytes
		//locker index: 2 bytes
		new de.polygonal.ds.mem.ByteMemory(mCapacity * MSG_SIZE, 'entity_system_message_que');
		#else
		new Vector<Int>(mCapacity * MSG_SIZE);
		#end
		
		mSize = 0;
		mFront = 0;
		
		mNextLocker = 0;
		mCurrLocker = -1;
		mLocker = new Array<Dynamic>();
		
		#if verbose
		L.d('found ${Msg.totalMessages()} message types', "es");
		#end
	}
	
	public function putData(o:Dynamic)
	{
		D.assert(mCurrLocker != -1);
		mLocker[mCurrLocker] = o;
	}
	
	public function getData():Dynamic
	{
		D.assert(mCurrLocker != -1);
		return mLocker[mCurrLocker];
	}
	
	public function enqueue(sender:E, recipient:E, type:Int, remaining:Int)
	{
		D.assert(sender != null);
		D.assert(recipient != null);
		D.assert(type >= 0 && type <= 0xFFFF);
		D.assert(mSize < mCapacity, "message queue exhausted");
		
		var i = (mFront + mSize) % mCapacity;
		mSize++;
		
		if (recipient.mFlags & (E.BIT_GHOST | E.BIT_SKIP_MSG | E.BIT_MARK_FREE) > 0)
		{
			//enqueue message even if recipient doesn't want it;
			//this is required for properly stopping a message propagation (when an entity calls stop())
			#if alchemy
			Mem.setI32(mQue.offset + i * MSG_SIZE, -1);
			#else
			mQue[i * MSG_SIZE] = -1;
			#end
			return;
		}
		
		#if (verbose == "extra")
		var senderName = sender.name == null ? "N/A" : sender.name;
		var recipientName = recipient.name == null ? "N/A" : recipient.name;
		
		if (senderName.length > 30) senderName = StringUtil.ellipsis(senderName, 30, 1, true);
		if (recipientName.length > 30) recipientName = StringUtil.ellipsis(recipientName, 30, 1, true);
		
		var msgName = Msg.name(type);
		if (msgName.length > 20) msgName = StringUtil.ellipsis(msgName, 20, 1, true);
		
		L.d(Printf.format('enqueue message %30s -> %-30s: %-20s (remaining: $remaining)', [senderName, recipientName, msgName]), "es");
		#end
		
		var senderId = sender.id;
		var recipientId = recipient.id;
		var q = mQue;
		
		#if alchemy
		var addr = q.getAddr(i * MSG_SIZE);
		Mem.setI32(addr     , senderId.inner);
		Mem.setI32(addr +  4, recipientId.inner);
		Mem.setI16(addr +  8, senderId.index);
		Mem.setI16(addr + 10, recipientId.index);
		Mem.setI16(addr + 12, type);
		Mem.setI16(addr + 14, remaining);
		Mem.setI16(addr + 16, mNextLocker);
		#else
		var addr = i * MSG_SIZE;
		q[addr    ] = senderId.inner;
		q[addr + 1] = recipientId.inner;
		q[addr + 2] = senderId.index;
		q[addr + 3] = recipientId.index;
		q[addr + 4] = type;
		q[addr + 5] = remaining;
		q[addr + 6] = mNextLocker;
		#end
		
		if (remaining == 0)
		{
			//use same locker for multiple recipients
			mCurrLocker = mNextLocker++;
		}
	}
	
	public function dispatch()
	{
		if (mIsDispatching || mSize == 0) return;
		mIsDispatching = true;
		
		var a = ES.mFreeList;
		
		var senderIndex:Int;
		var senderInner:Int;
		var recipientIndex:Int;
		var recipientInner:Int;
		var type:Int;
		var skipCount:Int;
		var sender:Entity;
		var recipient:Entity;
		
		var q = mQue;
		var c = mCapacity;
		var f = mFront;
		var k = 0;
		var i = 0;
		var iter = 0;
		
		#if verbose
		var numSkippedMessages = 0;
		var numDispatchedMessages = 0;
		#end
		
		while (mSize > 0)
		{
			//while there are buffered messages
			//process k buffered messages
			k = mSize;
			i = k;
			
			#if (verbose == "extra")
			L.d('iter $iter: dispatching $k messages ...', "es");
			iter++;
			#end
			
			while (i > 0)
			{
				#if alchemy
				var addr       = q.getAddr(f * MSG_SIZE);
				senderInner    = Mem.getI32(addr);
				recipientInner = Mem.getI32(addr  +  4);
				senderIndex    = Mem.getUI16(addr +  8);
				recipientIndex = Mem.getUI16(addr + 10);
				type           = Mem.getUI16(addr + 12);
				skipCount      = Mem.getUI16(addr + 14);
				mCurrLocker    = Mem.getUI16(addr + 16);
				#else
				var addr       = f * MSG_SIZE;
				senderInner    = q[addr    ];
				recipientInner = q[addr + 1];
				senderIndex    = q[addr + 2];
				recipientIndex = q[addr + 3];
				type           = q[addr + 4];
				skipCount      = q[addr + 5];
				mCurrLocker    = q[addr + 6];
				#end
				
				//ignore message?
				if (senderInner == -1)
				{
					#if verbose
					numSkippedMessages++;
					#end
					
					//dequeue
					f = (f + 1) % c;
					i--;
					continue;
				}
				
				sender = a[senderIndex];
				
				D.assert(sender != null);
				D.assert(sender.id != null);
				D.assert(sender.id.inner == senderInner);
				
				recipient = a[recipientIndex];
				
				D.assert(recipient != null);
				D.assert(recipient.id != null);
				D.assert(recipient.id.inner == recipientInner);
				
				//dequeue
				f = (f + 1) % c;
				i--;
				
				#if (verbose == "extra")
				var data = mLocker[mCurrLocker] != null ? '${mLocker[mCurrLocker]}' : "";
				var senderId = sender.name == null ? Std.string(sender.id) : sender.name;
				var recipientId = recipient.name == null ? Std.string(recipient.id) : recipient.name;
				
				if (senderId.length > 30) senderId = StringUtil.ellipsis(senderId, 30, 1, true);
				if (recipientId.length > 30) recipientId = StringUtil.ellipsis(recipientId, 30, 1, true);
				
				var msgName = Msg.name(type);
				if (msgName.length > 20) msgName = StringUtil.ellipsis(msgName, 20, 1, true);
				
				L.d(Printf.format('message %30s -> %-30s: %-20s $data', [senderId, recipientId, msgName]), "es");
				#end
				
				//notify recipient
				if (recipient.mFlags & (E.BIT_GHOST | E.BIT_SKIP_MSG | E.BIT_MARK_FREE) == 0)
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
				
				if (recipient.mFlags & E.BIT_STOP_PROPAGATION > 0)
				{
					//recipient stopped notification;
					//reset flag and skip remaining messages in current batch
					recipient.mFlags &= ~E.BIT_STOP_PROPAGATION;
					f = (f + skipCount) % c;
					i -= skipCount;
				}
			}
			mSize -= k;
			mFront = f;
		}
		
		#if verbose
		if (numDispatchedMessages + numSkippedMessages > 0)
			L.d('dispatched $numDispatchedMessages messages (skipped: $numSkippedMessages)', "es");
		#end
		
		//empty locker
		for (i in 0...mNextLocker)
			mLocker[i] = null;
		mNextLocker = 0;
		mCurrLocker = -1;
		
		mIsDispatching = false;
	}
}