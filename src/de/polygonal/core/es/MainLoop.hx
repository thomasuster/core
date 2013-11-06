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

import de.polygonal.core.event.IObservable;
import de.polygonal.core.event.IObserver;
import de.polygonal.core.time.Timebase;
import de.polygonal.core.time.TimebaseEvent;
import de.polygonal.core.time.Timeline;

class MainLoop extends Entity implements IObserver
{
	public var paused = false;
	
	//var _flatTree:Array<Entity>;
	//var _walker:Entity;
	//var _isCurrent:Bool;
	
	var _stack:Array<Entity>;
	var _top:Int;
	
	public function new()
	{
		super("MainLoop");
		Timebase.attach(this);
		
		/*_stack = [];
		_top = 1;
		
		while (top != 0)
		{
			var e = stack[--top];
			
			//process(e);
			
			var children = [];
			
			var c = e.child;
			while (c != null)
			{
				children.push(c);
				c = c.sibling;
			}
			
			//add in reverse order
			var i = children.length;
			while (i > 0)
			{
				stack[top++] = children[i];
			}
		}*/
		
		//_isCurrent = true;
		//_flatTree = [];
	}
	
	override function onFree()
	{
		Timebase.detach(this);
	}
	
	public function onUpdate(type:Int, source:IObservable, userData:Dynamic):Void 
	{
		if (paused) return;
		
		if (type == TimebaseEvent.TICK)
		{
			//rebuild();
			
			Timeline.advance();
			
			/*
			if (_isCurrent)
			{
				for (i in _flatTree)
				{
					if (i._bits & Entity.BIT_SKIP_TICK == 0)
						i.onTick(dt);
				}
			}
			else*/
			var dt:Float = userData;
			propagateTick(dt);
			
			EntitySystem.dispatchMessages();
		}
		else
		if (type == TimebaseEvent.RENDER)
		{
			var alpha:Float = userData;
			propagateDraw(alpha);
		}
	}
	
	function cacheSize()
	{
		
	}
	
	static function countPasses(r:Entity)
	{
		//iteratively counts the subtree size of every entity in this tree.s
		
		return;
		//first pass
		var e = r;
		while (e != null)
		{
			var p = e.parent;
			if (p != null)
			{
				//p._bits |= MARKED;
				//p.marked = true;
				//p.size++;
			}
			e = e.preorder;
		}

		var end = true;
		while (true)
		{
			e = r;
			end = true;
			while (e != null)
			{
				
				
				var p = e.parent;
				if (p != null)
				{
					/*if (e.marked && p.marked)
					{
						p.size += e.size;
						e.marked = false;
						
						//set final size flag to e..
						
						end = false;
					}*/
				}
				
				e = e.preorder;
			}
			
			if (end)
			{
				trace('done!');
				break;
			}
		}
	}
	
	/*function rebuild()
	{
		if (_bits & Entity.BIT_CHANGED > 0)
		{
			_bits &= ~Entity.BIT_CHANGED;
			_flatTree = [];
			_walker = child;
			_isCurrent = false;
		}
			
		if (_isCurrent) return;
		
		var a = _flatTree;
		var e = _walker;
		var i = 0;
		var k = 10;
		while (i++ < k && e != null)
		{
			e._bits &= ~Entity.BIT_CHANGED;
			
			if (e._bits & Entity.BIT_SKIP_SUBTREE > 0)
			{
				e = e.sibling != null ? e.sibling : e._preorder;
				continue;
			}
			
			if (e._bits & (Entity.BIT_GHOST) == 0)
				a.push(e);
			
			e = e._preorder;
		}
		
		if (e == null)
		{
			_isCurrent = true;
			L.w('flat completed');
		}
	}*/
}