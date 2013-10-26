package de.polygonal.core.es;

import de.polygonal.core.math.Limits;
import de.polygonal.core.es.Entity;
import de.polygonal.ds.IntHashSet;
import de.polygonal.ds.IntIntHashTable;
import haxe.ds.StringMap;
import haxe.ds.Vector;

import de.polygonal.core.util.Assert;

@:access(de.polygonal.core.es.Entity)
class EntityManager
{
	inline public static var MAX_SUPPORTED_ENTITIES = 0xFFFF;
	
	//unique id, incremented every time an entity is registered
	static var _nextInnerId = 0;
	
	//all existing entities
	static var _freeList:Vector<Entity>;
	
	//indices [0,3]: parent, child, sibling, last child (indices into the free list)
	//indices [4,6]: size (#descendants), tree depth, #children
	//index 7 is reserved
	static var _topology:Vector<Int>;
	
	static var _entitiesByName:StringMap<Array<Entity>> = null;
	static var _next:Vector<Int>;
	static var _free:Int;
	
	static var _types:IntHashSet;
	static var _msgQue:MsgQue;
	
	public static function init(maxEntities = 0x8000)
	{
		D.assert(maxEntities <= MAX_SUPPORTED_ENTITIES);
		
		_freeList = new Vector<Entity>(1 + maxEntities);
		_topology = new Vector<Int>(1 + maxEntities);
		_entitiesByName = new StringMap<Array<Entity>>();
		
		//start from 1 since first slot is reserved for null
		_next = new Vector<Int>(maxEntities);
		for (i in 1...maxEntities - 1) _next[i] = (i + 1);
		_next[maxEntities - 1] = -1;
		_free = 1;
		
		_types = new IntHashSet(512);
		_msgQue = new MsgQue();
	}
	
	public static function dispatchMessages()
		_msgQue.dispatch();

	inline public static function lookupByName(name:String):Array<Entity>
		return _entitiesByName.get(name);
		
	inline public static function lookup(id:EntityId):Entity
	{
		D.assert(id.inner != -1);
		return _freeList[id.index];
		
		/*Memory.setI32(0, 0xffff);
		Memory.setI32(4, 0xffff);
		var key = Memory.getDouble(0);
		
		Memory.setDouble(0, key);
		var a = Memory.getI32(0);
		var b = Memory.getI32(4);*/
		
		//var index = lower;
		//var inner = higher;
		//e = _freeList[index];
		//e != null && e.getInner() == inner
	}
	
	public static function free(e:Entity)
	{
		#if verbose
		L.d('freeing up ${e.size + 1} entities ...', "entity");
		#end
		
		if (e.size < 512)
			freeRecursive(e); //postorder traversal
		else
			freeIterative(e); //inverse levelorder traversal
	}
	
	static function freeRecursive(e:Entity)
	{
		var n = e.child;
		while (n != null)
		{
			freeRecursive(n);
			n = n.sibling;
		}
		
		e.onFree();
		remove(e);
		
		#if verbose
		L.d('freed $e', "entity");
		#end
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
			remove(e);
			#if verbose
			L.d('freed $e', "entity");
			#end
		}
	}
	
	public static function changeName(e:Entity, name:String)
	{
		if (e.name != null)
		{
			var table = _entitiesByName.get(e.name);
			table.remove(e);
		}
		
		e._name = name;
		registerName(e);
	}
	
	public static function add(e:Entity)
	{
		var i = _free;
		
		D.assert(i != -1);
		
		_free = _next[i];
		_freeList[i] = e;
		
		var id = new EntityId();
		id.inner = _nextInnerId++;
		id.index = i;
		e.id = id;
		
		//handle in macro??
		var t = _types;
		if (!t.has(e._type))
		{
			var type = e._type;
			
			t.set(type);
			t.set(type << 16 | type);
			
			var s = Type.getSuperClass(Type.getClass(e));
			while (s != null)
			{
				t.set(type << 16 | Entity.getClassType(s));
				s = Type.getSuperClass(s);
			}
		}
		
		if (e.name != null) registerName(e);
	}
	
	public static function remove(e:Entity)
	{
		D.assert(e.id != null);
		
		e.parent = e.child = e.sibling = e.preorder = null;
		
		var i = e.id.index;
		
		//nullify for gc
		_freeList[i] = null;
		
		var pos = i << 3;
		
		_topology[pos + 0] = 0;
		_topology[pos + 1] = 0;
		_topology[pos + 2] = 0;
		_topology[pos + 3] = 0;
		
		_topology[pos + 4] = 0;
		_topology[pos + 5] = 0;
		_topology[pos + 6] = 0;
		_topology[pos + 7] = 0;
		
		//mark as free
		_next[i] = _free;
		_free = i;
		
		//remove from name => entity mapping
		var table = _entitiesByName.get(e.name);
		if (table != null) table.remove(e);
		
		//wipe id
		e.id.inner = -1;
		e.id = null;
	}
	
	static function registerName(e:Entity)
	{
		var table = _entitiesByName.get(e.name);
		if (table == null)
		{
			table = [];
			_entitiesByName.set(e.name, table);
		}
		table.push(e);
	}
}