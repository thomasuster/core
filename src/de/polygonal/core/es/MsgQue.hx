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

@:publicFields
@:build(de.polygonal.core.util.IntConstants.build([I, F, B, S, O, USED], true, true))
class MsgBundle
{
	@:noCompletion var mInt:Int;
	@:noCompletion var mFloat:Float;
	@:noCompletion var mBool:Bool;
	@:noCompletion var mString:String;
	@:noCompletion var mObject:Dynamic;
	@:noCompletion var mFlags:Int;
	
	public var int(get_int, set_int):Int;
	@:noCompletion inline function get_int():Int
	{
		D.assert(mFlags & I > 0, "no int stored");
		return mInt;
	}
	@:noCompletion inline function set_int(value:Int):Int
	{
		D.assert(mFlags & USED == 0);
		
		mFlags |= I;
		mInt = value;
		return value;
	}
	
	public var float(get_float, set_float):Float;
	@:noCompletion inline function get_float():Float
	{
		D.assert(mFlags & F > 0, "no float stored");
		return mFloat;
	}
	@:noCompletion inline function set_float(value:Float):Float
	{
		D.assert(mFlags & USED == 0);
		
		mFlags |= F;
		mFloat = value;
		return value;
	}
	
	public var bool(get_bool, set_bool):Bool;
	@:noCompletion inline function get_bool():Bool
	{
		D.assert(mFlags & B > 0, "no bool stored");
		return mBool;
	}
	@:noCompletion inline function set_bool(value:Bool):Bool
	{
		D.assert(mFlags & USED == 0);
		
		mFlags |= B;
		mBool = value;
		return value;
	}
	
	public var string(get_string, set_string):String;
	@:noCompletion inline function get_string():String
	{
		D.assert(mFlags & S > 0, "no string stored");
		return mString;
	}
	@:noCompletion inline function set_string(value:String):String
	{
		D.assert(mFlags & USED == 0);
		
		mFlags |= S;
		mString = value;
		return value;
	}
	
	public var object(get_object, set_object):Dynamic;
	@:noCompletion inline function get_object():Dynamic
	{
		D.assert(mFlags & O > 0, "no object stored");	
		return mObject;
	}
	@:noCompletion inline function set_object(value:Dynamic):Dynamic
	{
		D.assert(mFlags & USED == 0);
		
		mFlags |= O;
		mObject = value;
		return value;
	}
	
	inline public function hasInt() return mFlags & I > 0;
	inline public function hasFloat() return mFlags & F > 0;
	inline public function hasBool() return mFlags & B > 0;
	inline public function hasString() return mFlags & S > 0;
	inline public function hasObject() return mFlags & O > 0;
	
	function new() {}
	
	@:noCompletion function toString():String
	{
		var a = [];
		if (mFlags & I > 0) a.push('int=$mInt');
		if (mFlags & F > 0) a.push('float=$mFloat');
		if (mFlags & B > 0) a.push('bool=$mBool');
		if (mFlags & S > 0) a.push('string=$mString');
		if (mFlags & O > 0) a.push('object=$mObject');
		if (a.length > 0) return "{MsgBundle, " + a.join(", ") + "}";
		return "{MsgBundle}";
	}
}

@:access(de.polygonal.core.es.Entity)
@:access(de.polygonal.core.es.EntitySystem)
class MsgQue
{
	inline static var MSG_SIZE =
	#if alchemy
	//sender+recipient inner: 2*4 bytes
	//sender+recipient index: 2*2 bytes
	//type, skip count, bundle index: 3*2 bytes
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
	var mCurrBundleIn:Int;
	var mCurrBundleOut:MsgBundle;
	var mFreeBundle:Int;
	var mBundles:Array<MsgBundle>;
	
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
		//bundle index: 2 bytes
		new de.polygonal.ds.mem.ByteMemory(mCapacity * MSG_SIZE, "entity_system_message_que");
		#else
		new Vector<Int>(mCapacity * MSG_SIZE);
		#end
		
		mSize = 0;
		mFront = 0;
		
		mFreeBundle = 0;
		mBundles = new Array<MsgBundle>();
		
		#if verbose
		L.d('found ${Msg.totalMessages()} message types', "es");
		#end
	}
	
	public function getMsgBundleIn():MsgBundle
	{
		if (mCurrBundleIn == -1) return null;
		return mBundles[mCurrBundleIn];
	}
	
	public function getMsgBundleOut():MsgBundle
	{
		mCurrBundleOut = mBundles[mFreeBundle];
		if (mCurrBundleOut == null) mCurrBundleOut = mBundles[mFreeBundle] = new MsgBundle();
		return mCurrBundleOut;
	}
	
	inline function clrBundle()
	{
		if (mCurrBundleOut != null)
		{
			mCurrBundleOut.mFlags = 0;
			mCurrBundleOut.mObject = null;
			mCurrBundleOut = null;
		}
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
		Mem.setI16(addr + 16, mFreeBundle);
		#else
		var addr = i * MSG_SIZE;
		q[addr    ] = senderId.inner;
		q[addr + 1] = recipientId.inner;
		q[addr + 2] = senderId.index;
		q[addr + 3] = recipientId.index;
		q[addr + 4] = type;
		q[addr + 5] = remaining;
		q[addr + 6] = mFreeBundle;
		#end
		
		//use same locker for multiple recipients
		//increment counter if batch is complete and data is set
		if (remaining == 0)
		{
			if (mCurrBundleOut != null && mCurrBundleOut.mFlags > 0)
			{
				mCurrBundleOut.mFlags |= MsgBundle.USED;
				mFreeBundle++; 
				mCurrBundleOut = null;
			}
		}
	}
	
	public function dispatch()
	{
		if (mSize == 0) return;
		
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
		
		#if verbose
		var numSkippedMessages = 0;
		var numDispatchedMessages = 0;
		#end
		
		#if (verbose == "extra")
		L.d('dispatching $mSize messages ...', "es");
		#end
		
		while (mSize > 0) //while there are buffered messages
		{
			#if alchemy
			var addr       = q.getAddr(mFront * MSG_SIZE);
			senderInner    = Mem.getI32(addr);
			recipientInner = Mem.getI32(addr  +  4);
			senderIndex    = Mem.getUI16(addr +  8);
			recipientIndex = Mem.getUI16(addr + 10);
			type           = Mem.getUI16(addr + 12);
			skipCount      = Mem.getUI16(addr + 14);
			mCurrBundleIn  = Mem.getUI16(addr + 16);
			#else
			var addr       = mFront * MSG_SIZE;
			senderInner    = q[addr    ];
			recipientInner = q[addr + 1];
			senderIndex    = q[addr + 2];
			recipientIndex = q[addr + 3];
			type           = q[addr + 4];
			skipCount      = q[addr + 5];
			mCurrBundleIn  = q[addr + 6];
			#end
			
			//ignore message?
			if (senderInner == -1)
			{
				#if verbose
				numSkippedMessages++;
				#end
				
				//dequeue
				mFront = (mFront + 1) % c;
				mSize--;
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
			mFront = (mFront + 1) % c;
			mSize--;
			
			#if (verbose == "extra")
			var data = mBundles[mCurrBundleIn] != null ? mBundles[mCurrBundleIn] : null;
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
			#if verbose
			else
				numSkippedMessages++;
			#end
			
			if (recipient.mFlags & E.BIT_STOP_PROPAGATION > 0)
			{
				throw 'stop';
				
				//recipient stopped notification;
				//reset flag and skip remaining messages in current batch
				recipient.mFlags &= ~E.BIT_STOP_PROPAGATION;
				mFront = (mFront + skipCount) % c;
				mSize -= skipCount;
			}
		}
		
		#if verbose
		if (numDispatchedMessages + numSkippedMessages > 0)
			L.d('dispatched $numDispatchedMessages messages (skipped: $numSkippedMessages)', "es");
		#end
		
		//clear bundles
		for (i in 0...mBundles.length)
		{
			D.assert(mBundles[i] != null);
			mBundles[i].mFlags = 0;
			mBundles[i].mObject = null;
		}
		mFreeBundle = 0;
		mCurrBundleIn = -1;
	}
}