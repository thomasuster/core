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

import de.polygonal.core.util.Assert;
import de.polygonal.core.util.ClassTools;
import de.polygonal.ds.IntIntHashTable;
import haxe.ds.IntMap;
import haxe.ds.StringMap;
import haxe.ds.Vector;

typedef ES = EntitySystem;

typedef EntitySystemConfig =
{
	/**
	 * Maximum capacity of the message queue.
	 * By default, a total of 32768 messages can be handled per game tick.
	 * This requires 896 KiB of memory (576 KiB if alchemy is used).
	 */
	maxMessageCount:Int,
	
	/**
	 * The total number of supported entities.
	 * Default is 0x8000.
	 */
	maxEntityCount:Int
}

@:access(de.polygonal.core.es.Entity)
@:access(de.polygonal.core.es.MsgQue)
class EntitySystem
{
	inline public static var MAX_SUPPORTED_ENTITIES = 0xFFFE;
	
	//unique id, incremented every time an entity is registered
	static var mNextInnerId = 0;
	
	//all existing entities
	static var mFreeList:Vector<Entity>;
	
	#if alchemy
	static var mNext:de.polygonal.ds.mem.ShortMemory;
	#else
	static var mNext:Vector<Int>;
	#end
	
	static var mFree:Int;
	
	//indices [0,3]: parent, child, sibling, last child (indices into the free list)
	//indices [4,6]: size (#descendants), tree depth, #children
	//index 7 is reserved
	#if alchemy
	static var mTopology:de.polygonal.ds.mem.ShortMemory;
	#else
	static var mTopology:Vector<Int>; //TODO use 16 bits
	#end
	
	//name => [entities by name]
	static var mEntitiesByName:StringMap<Entity> = null;
	
	//circular message buffer
	static var mMsgQue:MsgQue;
	
	//maps class x to all superclasses of x
	static var mInheritanceLookup:IntIntHashTable;
	
	//entities can store optional <key, value> pairs
	static var mProperties = new IntMap<StringMap<Dynamic>>();
	
	public static function init(?config:EntitySystemConfig)
	{
		if (mFreeList != null) return;
		
		if (config == null) config = {maxMessageCount: 0x8000, maxEntityCount: 0x8000};
		
		var maxEntities = config.maxMessageCount;
		
		D.assert(maxEntities > 0 && maxEntities <= MAX_SUPPORTED_ENTITIES);
		
		mFreeList = new Vector<Entity>(1 + maxEntities); //index 0 is reserved for null
		
		#if alchemy
		mTopology = new de.polygonal.ds.mem.ShortMemory((1 + maxEntities) << 3, "topology");
		#else
		mTopology = new Vector<Int>((1 + maxEntities) << 3);
		for (i in 0...mTopology.length) mTopology[i] = 0;
		#end
		
		mEntitiesByName = new StringMap<Entity>();
		
		//first element is stored at index=1 (0 is reserved for NULL)
		#if alchemy
		mNext = new de.polygonal.ds.mem.ShortMemory(1 + maxEntities, "es_freelist_shorts");
		for (i in 1...maxEntities)
			mNext.set(i, i + 1);
		mNext.set(maxEntities, -1);
		#else
		mNext = new Vector<Int>(1 + maxEntities);
		for (i in 1...maxEntities)
			mNext[i] = (i + 1);
		mNext[maxEntities] = -1;
		#end
		
		mFree = 1;
		
		mMsgQue = new MsgQue(config.maxMessageCount);
		
		mInheritanceLookup = new IntIntHashTable(1024);
		
		#if verbose
			//topology array
			var bytesUsed = 0;
			#if alchemy
			bytesUsed += mTopology.size * 2;
			bytesUsed += mNext.size * 2;
			bytesUsed += mMsgQue.mQue.size;
			#else
			bytesUsed += mTopology.length * 4;
			bytesUsed += mNext.length * 4;
			bytesUsed += mMsgQue.mQue.length * 4;
			#end
			
			bytesUsed += mFreeList.length * 4;
			
			L.d('using ${bytesUsed >> 10} KiB for managing $maxEntities entities and ${config.maxMessageCount} messages.', "es");
		#end
	}
	
	public static function free()
	{
		mFreeList = null;
		
		#if alchemy
		mTopology.free();
		mNext.free();
		#end
		
		mTopology = null;
		mEntitiesByName = null;
		mNext = null;
		mNextInnerId = 0;
		mInheritanceLookup.free();
		mInheritanceLookup = null;
	}
	
	public static function register(e:Entity)
	{
		D.assert(mFreeList != null, "call EntitySystem.init() first");
		D.assert(e.id == null && e.mFlags == 0, "Entity has been registered");
		
		var i = mFree;
		
		D.assert(i != -1);
		
		#if alchemy
		mFree = mNext.get(i);
		#else
		mFree = mNext[i];
		#end
		
		mFreeList[i] = e;
		
		var id = new EntityId();
		id.inner = mNextInnerId++;
		id.index = i;
		e.id = id;
		
		if (e.name != null) registerName(e);
		
		var lut = mInheritanceLookup;
		if (!lut.hasKey(e.type))
		{
			var t = e.type;
			lut.set(t, t);
			var sc:Class<Entity> = Reflect.field(Type.getClass(e), "SUPER_CLASS");
			while (sc != null)
			{
				mInheritanceLookup.set(t, Entity.getEntityType(sc));
				sc = Reflect.field(sc, "SUPER_CLASS");
			}
		}
	}
	
	public static function unregister(e:Entity)
	{
		D.assert(e.id != null);
		
		#if (verbose=="extra")
		L.d('$e is gone', "es");
		#end
		
		var i = e.id.index;
		
		//nullify for gc
		mFreeList[i] = null;
		
		var pos = i << 3;
		
		#if alchemy
		for (i in 0...8) mTopology.set(pos + i, 0);
		#else
		for (i in 0...8) mTopology[pos + i] = 0;
		#end
		
		//mark as free
		#if alchemy
		mNext.set(i, mFree);
		#else
		mNext[i] = mFree;
		#end
		mFree = i;
		
		//remove from name => entity mapping
		if (e.mFlags & Entity.BIT_GLOBAL_NAME > 0)
			mEntitiesByName.remove(e.name);
		
		
		//mark as removed by setting msb to one
		e.id.inner |= 0x80000000;
		e.id = null;
		
		//don't forget to nullify preorder pointer
		e.preorder = null;
	}
	
	public static function freeEntity(e:Entity)
	{
		#if verbose
		L.d('freeing up ${e.size + 1} entities ...', "es");
		#end
		
		if (e.size < 512)
			freeRecursive(e); //postorder traversal
		else
			freeIterative(e); //inverse levelorder traversal
	}
	
	inline public static function dispatchMessages() mMsgQue.dispatch();
	
	inline public static function getParent(e:Entity):Entity return mFreeList[get(pos(e, 0))];
	inline public static function setParent(e:Entity, parent:Entity) set(pos(e, 0), parent == null ? 0 : parent.id.index);
	
	inline public static function getChild(e:Entity):Entity return mFreeList[get(pos(e, 1))];
	inline public static function setChild(e:Entity, child:Entity) set(pos(e, 1), child == null ? 0 : child.id.index);
	
	inline public static function getSibling(e:Entity):Entity return mFreeList[get(pos(e, 2))];
	inline public static function setSibling(e:Entity, sibling:Entity) set(pos(e, 2), sibling == null ? 0 : sibling.id.index);
	
	inline public static function getLastChild(e:Entity):Entity return mFreeList[get(pos(e, 3))];
	inline public static function setLastChild(e:Entity, lastChild:Entity) set(pos(e, 3), lastChild == null ? 0 : lastChild.id.index);
	
	inline public static function getSize(e:Entity):Int return get(pos(e, 4));
	inline public static function setSize(e:Entity, value:Int) set(pos(e, 4), value);
		
	inline public static function getDepth(e:Entity):Int return get(pos(e, 5));
	inline public static function setDepth(e:Entity, value:Int) set(pos(e, 5), value);
		
	inline public static function getNumChildren(e:Entity):Int return get(pos(e, 6));
	inline public static function setNumChildren(e:Entity, value:Int) set(pos(e, 6), value);
	
	inline static function get(i:Int):Int
	{
		return
		#if alchemy
		mTopology.get(i);
		#else
		mTopology[i];
		#end
	}
	
	inline static function set(i:Int, value:Int)
	{
		#if alchemy
		mTopology.set(i, value);
		#else
		mTopology[i] = value;
		#end
	}
		
	inline static function pos(e:Entity, shift:Int):Int return (e.id.index << 3) + shift;
	
	inline public static function existsByName(name:String):Bool return mEntitiesByName.exists(name);
	
	inline public static function lookupByName(name:String):Entity return cast mEntitiesByName.get(name);
		
	inline public static function lookup(id:EntityId):Entity
	{
		if (id.index > 0)
		{
			var e = mFreeList[id.index];
			if (e != null)
				return (e.id.inner == id.inner) ? e : null;
			else
				return null;
		}
		else
			return null;
	}
	
	public static function changeName(e:Entity, newName:String)
	{
		if (e.name != null)
			mEntitiesByName.remove(e.name);
		e.mName = newName;
		registerName(e);
	}
	
	public static function prettyPrint(e:Entity):String
	{
		var s = "\n";
		for (i in 0...e.size + 1)
		{
			var d = e.depth;
			for (i in 0...d)
			{
				if (i == d - 1)
					s += "|---";
				else
					s += "|   ";
			}
			s += '[${e.name},${ClassTools.getClassName(e)}]\n';
			e = e.preorder;
		}
		return s;
	}
	
	static function freeRecursive(e:Entity)
	{
		var n = e.child;
		while (n != null)
		{
			var sibling = n.sibling;
			freeRecursive(n);
			n = sibling;
		}
		
		e.onFree();
		unregister(e);
	}
	
	static function freeIterative(e:Entity)
	{
		var k = e.size + 1;
		var a = new Vector<Entity>(k);
		for (i in 0...k) a[i] = null;
		
		var q = [e];
		var i = 0;
		var s = 1;
		var j, c;
		while (i < s)
		{
			j = q[i++];
			a[--k] = j; //add in reverse order
			c = j.child;
			while (c != null)
			{
				q[s++] = c;
				c = c.sibling;
			}
		}
		
		for (e in a)
		{
			e.onFree();
			unregister(e);
		}
	}
	
	static function registerName(e:Entity)
	{
		D.assert(e.id != null, "Entity is not registered, call EntitySystem.register() before");
		
		if (mEntitiesByName.exists(e.name))
			throw '${e.name} already registered to ${mEntitiesByName.get(e.name)}';
		
		mEntitiesByName.set(e.name, e);
		
		#if verbose
		L.d('registered entity by name: $e', "es");
		#end
	}
}