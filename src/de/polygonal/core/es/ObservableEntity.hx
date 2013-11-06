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

@:access(de.polygonal.core.es.EntitySystem)
class ObservableEntity extends Entity
{
	var _observersByType:IntHashTable<Array<EntityId>>;
	
	public function new(name:String = null)
	{
		_observersByType = new IntHashTable<Array<EntityId>>(256, 1024);
		
		super(name);
	}
	
	override public function free()
	{
		super.free();
		
		_observersByType.free();
		_observersByType = null;
	}
	
	public function notify(type:Int)
	{
		var observers = _observersByType.get(type);
		if (observers == null) return;
		
		var q = EntitySystem._msgQue;
		var k = observers.length;
		while (k-- > 0)
		{
			var id = observers[k];
			q.enqueue(this, EntitySystem.lookup(id), type, k);
			if (id.inner < 0)
				observers.pop();
		}
	}
	
	public function attach(e:Entity, type:Int):Bool
	{
		var observers = _observersByType.get(type);
		if (observers == null)
		{
			observers = [];
			_observersByType.set(type, observers);
		}
		
		for (i in observers)
			if (i.equals(e.id)) return false;
		
		observers.push(e.id);
		
		return true;
	}
	
	public function detach(e:Entity, type:Int):Bool
	{
		var observers = _observersByType.get(type);
		if (observers == null) return false;
		var k = observers.length;
		for (i in 0...k)
		{
			if (observers[i].equals(e.id))
			{
				observers[i] = observers[k - 1];
				observers.pop();
				return true;
			}
		}
		
		return false;
	}
}