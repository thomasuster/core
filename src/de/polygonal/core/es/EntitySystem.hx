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
import de.polygonal.core.util.ClassUtil;
import de.polygonal.ds.IntHashTable;
import de.polygonal.ds.IntIntHashTable;
import de.polygonal.ds.mem.ShortMemory;
import haxe.ds.StringMap;
import haxe.ds.Vector;


@:access(de.polygonal.core.es.Entity)
@:access(de.polygonal.core.es.MsgQue)
class EntitySystem
{
	inline public static var MAX_SUPPORTED_ENTITIES = 0xFFFE;
	
	//unique id, incremented every time an entity is registered
	static var _nextInnerId = 0;
	
	//all existing entities
	static var _freeList:Vector<Entity>;
	
	#if alchemy
	static var _next:ShortMemory;
	#else
	static var _next:Vector<Int>;
	#end
	
	static var _free:Int;
	
	//indices [0,3]: parent, child, sibling, last child (indices into the free list)
	//indices [4,6]: size (#descendants), tree depth, #children
	//index 7 is reserved
	#if alchemy
	static var _topology:de.polygonal.ds.mem.ShortMemory;
	#else
	static var _topology:Vector<Int>; //TODO use 16 bits
	#end
	
	//name => [entities by name]
	static var _entitiesByName:StringMap<Array<Entity>> = null;
	
	//circular message buffer
	static var _msgQue:MsgQue;
	
	//maps class x to all superclasses of x
	static var _inheritanceLookup:IntIntHashTable;
	
	public static function init(maxEntities = 0x8000)
	{
		if (_freeList != null) return;
		
		D.assert(maxEntities <= MAX_SUPPORTED_ENTITIES);
		
		_freeList = new Vector<Entity>(1 + maxEntities); //index 0 is reserved for null
		
		#if alchemy
		_topology = new ShortMemory((1 + maxEntities) << 3, "topology");
		#else
		_topology = new Vector<Int>((1 + maxEntities) << 3);
		#end
		
		_entitiesByName = new StringMap<Array<Entity>>();
		
		//start from index=1 (reserved for null)
		#if alchemy
		_next = new ShortMemory(1 + maxEntities);
		for (i in 1...maxEntities)
			_next.set(i, i + 1);
		_next.set(maxEntities, -1);
		#else
		_next = new Vector<Int>(1 + maxEntities);
		for (i in 1...maxEntities)
			_next[i] = (i + 1);
		_next[maxEntities] = -1;
		#end
		
		_free = 1;
		
		_msgQue = new MsgQue();
		
		_inheritanceLookup = new IntIntHashTable(1024);
		
		#if verbose
			//topology array
			var bytesUsed = 0;
			#if alchemy
			bytesUsed += _topology.size * 2;
			bytesUsed += _next.size * 2;
			#else
			bytesUsed += _topology.length * 4;
			bytesUsed += _next.length * 4;
			#end
			
			bytesUsed += _msgQue._que.length * 4;
			bytesUsed += _freeList.length * 4;
			
			L.d('using ${bytesUsed >> 10} KiB for managing $maxEntities entities and buffering ${MsgQue.MAX_SIZE} messages.');
		#end
	}
	
	public static function free()
	{
		_freeList = null;
		
		#if alchemy
		_topology.free();
		_next.free();
		#end
		
		_topology = null;
		_entitiesByName = null;
		_next = null;
		_nextInnerId = 0;
		_inheritanceLookup.free();
		_inheritanceLookup = null;
	}
	
	public static function register(e:Entity)
	{
		D.assert(_freeList != null, "call EntitySystem.init() first");
		D.assert(e.id == null && e._flags == 0, "Entity has been registered");
		
		var i = _free;
		
		D.assert(i != -1);
		
		#if alchemy
		_free = _next.get(i);
		#else
		_free = _next[i];
		#end
		
		_freeList[i] = e;
		
		var id = new EntityId();
		id.inner = _nextInnerId++;
		id.index = i;
		e.id = id;
		
		if (e.name != null) registerName(e);
		
		var lut = _inheritanceLookup;
		if (!lut.hasKey(e.type))
		{
			var t = e.type;
			lut.set(t, t);
			untyped
			{
				var sc:Class<Dynamic> = Type.getClass(e).SUPER_CLASS;
				while (sc != null)
				{
					_inheritanceLookup.set(t, Entity.getClassType(sc));
					sc = sc.SUPER_CLASS;
				}
			}
		}
	}
	
	public static function unregister(e:Entity)
	{
		D.assert(e.id != null);
		
		#if verbose
		L.d('$e is gone', "entity");
		#end
		
		var i = e.id.index;
		
		//nullify for gc
		_freeList[i] = null;
		
		var pos = i << 3;
		
		#if alchemy
		for (i in 0...8) _topology.set(i, 0);
		#else
		for (i in 0...8) _topology[pos + i] = 0;
		#end
		
		//mark as free
		#if alchemy
		_next.set(i, _free);
		#else
		_next[i] = _free;
		#end
		_free = i;
		
		//remove from name => entity mapping
		var table = _entitiesByName.get(e.name);
		if (table != null) table.remove(e);
		
		//mark as removed by setting msb to one
		e.id.inner |= 0x80000000;
		e.id = null;
		
		//don't forget to nullify preorder pointer
		e.preorder = null;
	}
	
	public static function freeEntity(e:Entity)
	{
		#if verbose
		L.d('freeing up ${e.size + 1} entities ...', "entity");
		#end
		
		if (e.size < 512)
			freeRecursive(e); //postorder traversal
		else
			freeIterative(e); //inverse levelorder traversal
	}
	
	inline public static function dispatchMessages()
		_msgQue.dispatch();
	
	inline public static function getParent(e:Entity):Entity return _freeList[get(pos(e, 0))];
	inline public static function setParent(e:Entity, parent:Entity) set(pos(e, 0), parent == null ? 0 : parent.id.index);
	
	inline public static function getChild(e:Entity):Entity return _freeList[get(pos(e, 1))];
	inline public static function setChild(e:Entity, child:Entity) set(pos(e, 1), child == null ? 0 : child.id.index);
	
	inline public static function getSibling(e:Entity):Entity return _freeList[get(pos(e, 2))];
	inline public static function setSibling(e:Entity, sibling:Entity) set(pos(e, 2), sibling == null ? 0 : sibling.id.index);
	
	inline public static function getLastChild(e:Entity):Entity return _freeList[get(pos(e, 3))];
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
		_topology.get(i);
		#else
		_topology[i];
		#end
	}
	
	inline static function set(i:Int, value:Int)
	{
		#if alchemy
		_topology.set(i, value);
		#else
		_topology[i] = value;
		#end
	}
		
	inline static function pos(e:Entity, shift:Int):Int return (e.id.index << 3) + shift;
	
	inline public static function lookupByName(name:String):Array<Entity> return _entitiesByName.get(name);
		
	inline public static function lookup(id:EntityId):Entity
	{
		if (id.index > 0)
		{
			var e = _freeList[id.index];
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
		//unregister
		if (e.name != null)
		{
			var table = _entitiesByName.get(e.name);
			table.remove(e);
		}
		
		//register
		e._name = newName;
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
			
			var type = ',' + ClassUtil.getUnqualifiedClassName(e);
			s += '[${e.name}$type]\n';
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
		
		var table = _entitiesByName.get(e.name);
		if (table == null)
		{
			table = [];
			_entitiesByName.set(e.name, table);
		}
		table.push(e);
		
		#if verbose
		L.d('registered entity by name: $e', "entity");
		#end
	}
}