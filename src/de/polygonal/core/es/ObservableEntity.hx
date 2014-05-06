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

import de.polygonal.core.es.EntitySystem.ES;
import de.polygonal.core.es.MsgQue.MsgBundle;
import de.polygonal.ds.IntHashTable;
import de.polygonal.ds.IntIntHashTable;
import de.polygonal.core.util.Assert;
import de.polygonal.ds.Vector;
import haxe.ds.IntMap;

@:access(de.polygonal.core.es.EntitySystem)
class ObservableEntity extends Entity
{
	var mObservers:Array<EntityId>;
	var mAttachStatus1:IntIntHashTable;
	var mAttachStatus2:IntMap<Bool>;
	
	//var mObserversByType:Vector<Array<EntityId>>;
	//var mObserversByType2:IntHashTable<EntityId>;
	
	public function new(name:String = null)
	{
		mObservers = [];
		mAttachStatus1 = new IntIntHashTable(256);
		mAttachStatus2 = new IntMap<Bool>();
		
		//mObserversByType = new Vector<Array<EntityId>>(Msg.totalMessages());
		//for (i in 0...Msg.totalMessages()) mObserversByType[i] = [];
		//mObserversByType2 = new IntHashTable<EntityId>(4096);
		//type => id.1
		//type => id.2
		
		super(name);
	}
	
	override public function free()
	{
		super.free();
		
		mObservers = [];
		mAttachStatus1.free();
		mAttachStatus1 = null;
		mAttachStatus2 = null;
	}
	
	public function notify(type:Int)
	{
		var all = mObservers;
		
		var q = Entity.getMsgQue();
		var k = all.length;
		var j = k;
		
		//remove invalid entities
		while (j-- > 0)
		{
			if (all[j].inner < 0)
			{
				markRemoved(all[j]);
				all.pop();
				k--;
			}
		}
		
		//enqueue messages
		j = k;
		while (j-- > 0)
			q.enqueue(this, ES.lookup(all[j]), type, --k);
	}
	
	public function attach(e:Entity):Bool
	{
		var id = e.id;
		
		//is entity valid?
		if (id == null || id.inner < 0) return false;
		
		var exists1 = mAttachStatus1.hasKey(id.inner);
		var exists2 = mAttachStatus2.exists(id.inner);
		D.assert(exists1 == exists2);
		
		if (exists1) return false;
		
		addToList(id);
		markAdded(id);
		
		return true;
	}
	
	public function detach(e:Entity):Bool
	{
		var id = e.id;
		
		//is entity valid?
		if (id == null || id.inner < 0) return false;
		
		//exists?
		var exists1 = mAttachStatus1.hasKey(id.inner);
		var exists2 = mAttachStatus2.exists(id.inner);
		D.assert(exists1 == exists2);
		
		if (!exists1) return false;
		
		removeFromList(id);
		markRemoved(id);
		
		return true;
	}
	
	function addToList(id:EntityId)
	{
		mObservers.push(id);
	}
	
	function removeFromList(id:EntityId):Bool
	{
		var list = mObservers;
		var k = list.length;
		for (i in 0...k)
		{
			if (list[i].equals(id))
			{
				list[i] = list[k - 1];
				list.pop();
				return true;
			}
		}
		return false;
	}
	
	inline function markAdded(id:EntityId)
	{
		#if debug
		var success = mAttachStatus1.setIfAbsent(id.inner, 1);
		D.assert(success);
		D.assert(!mAttachStatus2.exists(id.inner));
		mAttachStatus2.set(id.inner, true);
		#else
		mAttachStatus1.setIfAbsent(id.inner, 1);
		mAttachStatus2.set(id.inner, true);
		#end
	}
	
	inline function markRemoved(id:EntityId)
	{
		#if debug
		var success = mAttachStatus1.clr(id.inner & 0x7FFFFFFF);
		D.assert(success);
		var success = mAttachStatus2.remove(id.inner & 0x7FFFFFFF);
		D.assert(success);
		#else
		mAttachStatus1.clr(id.inner & 0x7FFFFFFF);
		mAttachStatus2.remove(id.inner & 0x7FFFFFFF);
		#end
	}
}