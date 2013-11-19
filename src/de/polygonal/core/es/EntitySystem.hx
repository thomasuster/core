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
import de.polygonal.ds.IntIntHashTable;
import haxe.ds.StringMap;
import haxe.ds.Vector;

@:access(de.polygonal.core.es.Entity)
class EntitySystem
{
	inline public static var MAX_SUPPORTED_ENTITIES = 0xFFFE;
	
	//unique id, incremented every time an entity is registered
	static var _nextInnerId = 0;
	
	//all existing entities
	static var _freeList:Vector<Entity>;
	static var _next:Vector<Int>;
	static var _free:Int;
	
	//indices [0,3]: parent, child, sibling, last child (indices into the free list)
	//indices [4,6]: size (#descendants), tree depth, #children
	//index 7 is reserved
	static var _topology:Vector<Int>; //TODO use 16 bits
	
	//name => [entities by name]
	static var _entitiesByName:StringMap<Array<Entity>> = null;
	
	//circular message buffer
	static var _msgQue:MsgQue;
	
	//maps class x to all superclasses of x
	static var _inheritanceLookup:IntIntHashTable;
	
	static var _initialized:Bool = false;
	
	public static function init(maxEntities = 0x8000)
	{
		if (_initialized) return;
		
		D.assert(maxEntities <= MAX_SUPPORTED_ENTITIES);
		_initialized = true;
		
		_freeList = new Vector<Entity>(1 + maxEntities); //index 0 is reserved for null
		_topology = new Vector<Int>((1 + maxEntities) << 3);
		_entitiesByName = new StringMap<Array<Entity>>();
		
		//start from index=1 (reserved for null)
		_next = new Vector<Int>(1 + maxEntities);
		for (i in 1...maxEntities)
			_next[i] = (i + 1);
		_next[maxEntities] = -1;
		_free = 1;
		
		_msgQue = new MsgQue();
		
		_inheritanceLookup = new IntIntHashTable(1024);
	}
	
	public static function free()
	{
		_freeList = null;
		_topology = null;
		_entitiesByName = null;
		_next = null;
		_nextInnerId = 0;
		_inheritanceLookup.free();
		_inheritanceLookup = null;
		_initialized = false;
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
		
		if (e.name != null) registerName(e);
		
		if (!_inheritanceLookup.hasKey(e.type))
		{
			var sc = Type.getSuperClass(Type.getClass(e));
			while (sc != null)
			{
				_inheritanceLookup.set(e.type, Entity.getClassType(sc));
				sc = Type.getSuperClass(sc);
			}
		}
	}
	
	public static function remove(e:Entity)
	{
		D.assert(e.id != null);
		
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
		
		//mark as removed by setting msb to one
		e.id.inner |= 0x80000000;
		
		e.id = null;
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

	inline public static function getParent(e:Entity):Entity return _freeList[_topology[pos(e, 0)]];
	inline public static function setParent(e:Entity, parent:Entity) _topology[pos(e, 0)] = parent == null ? 0 : parent.id.index;
	
	inline public static function getChild(e:Entity):Entity return _freeList[_topology[pos(e, 1)]];
	inline public static function setChild(e:Entity, child:Entity) _topology[pos(e, 1)] = child == null ? 0 : child.id.index;
	
	inline public static function getSibling(e:Entity):Entity return _freeList[_topology[pos(e, 2)]];
	inline public static function setSibling(e:Entity, sibling:Entity) _topology[pos(e, 2)] = sibling == null ? 0 : sibling.id.index;
	
	inline public static function getLastChild(e:Entity):Entity return _freeList[_topology[pos(e, 3)]];
	inline public static function setLastChild(e:Entity, lastChild:Entity) _topology[pos(e, 3)] = lastChild == null ? 0 : lastChild.id.index;
	
	inline public static function getSize(e:Entity):Int return _topology[pos(e, 4)];
	inline public static function setSize(e:Entity, value:Int) _topology[pos(e, 4)] = value;
		
	inline public static function getDepth(e:Entity):Int return _topology[pos(e, 5)];
	inline public static function setDepth(e:Entity, value:Int) _topology[pos(e, 5)] = value;
		
	inline public static function getNumChildren(e:Entity):Int return _topology[pos(e, 6)];
	inline public static function setNumChildren(e:Entity, value:Int) _topology[pos(e, 6)] = value;
		
	inline static function pos(e:Entity, shift:Int):Int return (e.id.index << 3) + shift;
	
	inline public static function lookupByName(name:String):Array<Entity> return _entitiesByName.get(name);
		
	inline public static function lookup(id:EntityId):Entity
	{
		var e = _freeList[id.index];
		if (e != null)
			return (e.id.inner == id.inner) ? e : null;
		else
			return null;
	}
	
	public static function changeName(e:Entity, newName:String)
	{
		if (e.name != null)
		{
			var table = _entitiesByName.get(e.name);
			table.remove(e);
		}
		
		e._name = newName;
		registerName(e);
	}
	
	public static function prettyPrint(e:Entity):String
	{
		if (e.freed) return "null";
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
			
			var type = ClassUtil.getUnqualifiedClassName(e);
			type = type == "Entity" ? "" : ',$type';
			
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