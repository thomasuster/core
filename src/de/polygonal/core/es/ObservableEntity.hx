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

import de.polygonal.ds.IntHashTable;
import de.polygonal.ds.IntIntHashTable;

@:access(de.polygonal.core.es.EntitySystem)
class ObservableEntity extends Entity
{
	var _observers:Array<EntityId>;
	var _observersByType:IntHashTable<Array<EntityId>>;
	var _attachStatus:IntIntHashTable;
	
	public function new(name:String = null)
	{
		_observers = [];
		_observersByType = new IntHashTable<Array<EntityId>>(256);
		_attachStatus = new IntIntHashTable(256);
		super(name);
	}
	
	override public function free()
	{
		super.free();
		
		_observers = [];
		_observersByType.free();
		_observersByType = null;
		_attachStatus.free();
		_attachStatus = null;
	}
	
	public function notify(type:Int)
	{
		var sub = _observersByType.get(type);
		var all = _observers;
		
		var q = Entity.getMsgQue();
		var i = sub != null ? sub.length : 0;
		var j = _observers.length;
		var k = i + j;
		
		//process filtered list
		while (i-- > 0)
		{
			var id = sub[i];
			q.enqueue(this, EntitySystem.lookup(id), type, --k);
			if (id.inner < 0)
			{
				sub.pop();
				_attachStatus.clr(id.inner & 0x7fffffff);
			}
		}
		
		//process unfiltered list
		while (j-- > 0)
		{
			var id = all[j];
			q.enqueue(this, EntitySystem.lookup(id), type, --k);
			if (id.inner < 0)
			{
				all.pop();
				_attachStatus.clr(id.inner & 0x7fffffff);
			}
		}
	}
	
	public function attach(e:Entity, type:Int = -1):Bool
	{
		var id = e.id;
		
		//quit if entity is invalid
		if (id == null || id.inner < 0) return false;
		
		//already attached?
		if (_attachStatus.hasKey(id.inner))
		{
			var existingType = _attachStatus.get(id.inner);
			
			//quit if nothing changed
			if (existingType == type) return false;
			
			//shift entity from filtered -> unfiltered list
			if (existingType != -1 && type == -1)
				removeFromList(_observersByType.get(existingType), id);
		}
		
		//add to observer list
		var list = getList(type);
		list.push(id);
		
		//mark as attached
		_attachStatus.set(id.inner, type);
		return true;
	}
	
	public function detach(e:Entity, type:Int = -1):Bool
	{
		var id = e.id;
		
		//quit if entity is invalid
		if (id == null || id.inner < 0) return false;
		
		//quit if entity is not attached
		if (!_attachStatus.hasKey(id.inner))
			return false;
		
		var list = getList(type);
		removeFromList(list, id);
		return true;
	}
	
	function getList(type:Int):Array<EntityId>
	{
		if (type == -1)
			return _observers;
		else
		{
			var a = _observersByType.get(type);
			if (a == null)
			{
				a = [];
				_observersByType.set(type, a);
			}
			return a;
		}
	}
	
	function removeFromList(list:Array<EntityId>, id:EntityId)
	{
		var k = list.length;
		for (i in 0...k)
		{
			if (list[i].equals(id))
			{
				list[i] = list[k - 1];
				list.pop();
				break;
			}
		}
	}
}