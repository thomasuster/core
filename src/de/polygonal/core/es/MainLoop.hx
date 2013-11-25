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

import de.polygonal.core.es.Entity in E;
import de.polygonal.core.es.EntitySystem in ES;

@:access(de.polygonal.core.es.EntitySystem)
class MainLoop extends E implements IObserver
{
	public var paused = false;
	
	var _stack:Array<E>;
	var _top:Int;
	
	public function new()
	{
		super(MainLoop.ENTITY_NAME);
		
		Timebase.init();
		Timebase.attach(this);
		Timeline.init();
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
			//process scheduled events
			Timeline.advance();
			
			//advance all entities
			var dt:Float = userData;
			propagateTick(dt);
			
			//remove or free marked entities
			commitBufferedChanges();
			
			//dispatch buffered messages
			EntitySystem.dispatchMessages();
			
			//alter topology
			EntitySystem.commitBufferedChange();
		}
		else
		if (type == TimebaseEvent.RENDER)
		{
			//draw all entities
			var alpha:Float = userData;
			alpha = 1;
			propagateDraw(alpha);
		}
	}
	
	public function propagateTick(dt:Float)
	{
		//invoke onTick() on all entities in this tree
		var e = child;
		while (e != null)
		{
			if (e._flags & (E.BIT_GHOST | E.BIT_SKIP_TICK | E.BIT_MARK_FREE) == 0) e.onTick(dt);
			
			if (e._flags & (E.BIT_SKIP_SUBTREE | E.BIT_MARK_REMOVE) > 0)
			{
				e = e.nextSubtree();
				continue;
			}
			e = e.preorder;
		}
	}
	
	function propagateDraw(alpha:Float)
	{
		//invoke onDraw() on all entities in this tree
		var e = child;
		while (e != null)
		{
			if (e._flags & (E.BIT_GHOST | E.BIT_SKIP_DRAW | E.BIT_MARK_FREE) == 0) e.onDraw(dt);
			
			if (e._flags & (E.BIT_SKIP_SUBTREE | E.BIT_MARK_REMOVE) > 0)
			{
				e = e.nextSubtree();
				continue;
			}
			e = e.preorder;
		}
	}
	
	function commitBufferedChanges()
	{
		//remove or free marked entities; this is done in a separate step because iterating and modifiying
		//a tree at the same time is complex and error-prone.
		var e = child, p, next;
		while (e != null)
		{
			next = e.preorder;
			
			if (e._flags & (E.BIT_MARK_REMOVE | E.BIT_MARK_FREE) > 0)
			{
				if (e._flags & E.BIT_MARK_REMOVE > 0)
				{
					//remember parent
					var p = e.parent;
					
					//force removal by setting commit flag
					e._flags |= E.BIT_COMMIT_REMOVE;
					p.remove(e);
					
					#if verbose
					L.d('entity $e was removed');
					#end
					
					//skip subtree of e
					next = p.preorder;
				}
				else
				if (e._flags & E.BIT_MARK_FREE > 0)
				{
					next = e.nextSubtree();
					
					//disconnect subtree rooted at this entity
					e.parent.remove(e);
					
					//bottom-up deconstruction (calls onFree() on all descendants)
					EntitySystem.freeEntity(e);
				}
			}
			
			e = next;
		}
	}
}