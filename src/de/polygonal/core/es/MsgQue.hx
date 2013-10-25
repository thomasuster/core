package de.polygonal.core.es;

import de.polygonal.core.util.Assert;

@:access(de.polygonal.core.es.Entity)
@:access(de.polygonal.core.es.EntityManager)
class MsgQue
{
	static var MAX_SIZE = 1 << 15; // (alchemy) / 768KiB
	
	var _que:haxe.ds.Vector<Int>;
	var _capacity:Int;
	var _size:Int;
	var _front:Int;
	
	public function new()
	{
		_capacity = 6 * MAX_SIZE;
		_size = 0;
		_front = 0;
		
		#if alchemy
		//4 shorts and 4 ints = 16 bytes per message: 512KiB @ 0x8000
		_que = new de.polygonal.ds.mem.ByteMemory(_capacity * 16, "msg_que_buffer");
		#else
		//768KiB @ 0x8000
		_que = new haxe.ds.Vector<Int>(_capacity);
		#end
	}
	
	public function enqueue(sender:Entity, recipient:Entity, type:Int, remaining:Int)
	{
		D.assert(sender != null);
		D.assert(recipient != null);
		D.assert(type >= 0 && type <= 0xffff);
		D.assert(_size < MAX_SIZE);
		
		var i = (_front + _size++ * 6) % _capacity;
		
		if (recipient._bits & (Entity.BIT_GHOST | Entity.BIT_SKIP_MSG) > 0)
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
		
		/*#if alchemy
		flash.Memory.setI16(i +  0, senderId.index);
		flash.Memory.setI16(i +  2, recipientId.index);
		flash.Memory.setI32(i +  4, senderId.inner);
		flash.Memory.setI32(i +  8, recipientId.inner);
		flash.Memory.setI16(i + 12, type);
		flash.Memory.setI16(i + 14, remaining);
		#end*/
	}
	
	public function dispatch()
	{
		var a = EntityManager._freeList;
		
		var senderIndex:Int;
		var senderInner:Int;
		var recipientIndex:Int;
		var recipientInner:Int;
		var type:Int;
		var skipCount:Int;
		
		var c = _capacity;
		var s = _size;
		var f = _front;
		
		while (s > 0)
		{
			senderIndex    = _que[f + 0];
			recipientIndex = _que[f + 1];
			senderInner    = _que[f + 2];
			recipientInner = _que[f + 3];
			type           = _que[f + 4];
			skipCount      = _que[f + 5];
			
			//ignore message?
			if (senderIndex == -1)
			{
				f = (f + 6) % c;
				s--;
				continue;
			}
			
			var sender = a[senderIndex];
			if (sender == null)
			{
				//skip message if sender was removed
				f = (f + 6) % c;
				s--;
				continue;
			}
			
			var recipient = a[recipientIndex];
			if (recipient == null)
			{
				//skip message if recipient was removed
				f = (f + 6) % c;
				s--;
				continue;
			}
			
			if (sender.id.inner != senderInner)
			{
				//skip message if sender was removed+replaced
				f = (f + 6) % c;
				s--;
				continue;
			}
			
			if (recipient.id.inner != recipientInner)
			{
				//skip message if recipient was removed+replaced
				f = (f + 6) % c;
				s--;
				continue;
			}
			
			//dequeue
			f = (f + 6) % c;
			s--;
			
			//notify recipient
			recipient.onMsg(type, sender);
			if (recipient._bits & Entity.BIT_STOP_PROPAGATION > 0)
			{
				//recipient stopped notification;
				//reset flag and skip remaining messages in current batch
				recipient._bits &= ~Entity.BIT_STOP_PROPAGATION;
				f += (6 * skipCount) % c;
				s -= skipCount;
			}
		}
		
		_size = s;
		_front = f;
	}
}