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
import haxe.ds.Vector;

import de.polygonal.core.es.Entity in E;
import de.polygonal.core.es.EntitySystem in ES;

@:access(de.polygonal.core.es.EntitySystem)
class MainLoop extends Entity implements IObserver
{
	public var paused = false;
	
	var _stack:Array<E>;
	var _top:Int;
	var _scratchList:Vector<E>;
	var _maxSize:Int;
	
	public function new()
	{
		super(MainLoop.ENTITY_NAME);
		
		Timebase.init();
		Timebase.attach(this);
		Timeline.init();
		
		_scratchList = new Vector<E>(ES.MAX_SUPPORTED_ENTITIES);
		_maxSize = 0;
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
			
			//dispatch buffered messages
			EntitySystem.dispatchMessages();
			
			//free marked entities
			freeEntities();
		}
		else
		if (type == TimebaseEvent.RENDER)
		{
			//draw all entities
			var alpha:Float = userData;
			propagateDraw(alpha);
			
			//prune scratch list for gc at regular intervals
			if (Timebase.processedFrames % 60 == 0)
			{
				var k = _maxSize;
				_maxSize = 0;
				var list = _scratchList;
				for (i in 0...k) list[i] = null;
			}
		}
	}
	
	function propagateTick(dt:Float)
	{
		var list = _scratchList;
		var k = 0;
		var e = child;
		while (e != null)
		{
			if (e._flags & E.BIT_SKIP_SUBTREE != 0)
			{
				e = e.nextSubtree();
				if (e != null)
					list[k++] = e;
			}
			else
			{
				list[k++] = e;
				e = e.preorder;
			}
		}
		
		if (k > _maxSize) _maxSize = k;
		
		for (i in 0...k)
		{
			e = list[i];
			if (e._flags & (E.BIT_GHOST | E.BIT_SKIP_TICK | E.BIT_MARK_FREE | E.BIT_SKIP_UPDATE) == 0)
				e.onTick(dt);
		}
	}
	
	function propagateDraw(alpha:Float)
	{
		var list = _scratchList;
		var k = 0;
		var e = child;
		while (e != null)
		{
			if (e._flags & E.BIT_SKIP_SUBTREE != 0)
			{
				e = e.nextSubtree();
				if (e != null)
					list[k++] = e;
			}
			else
			{
				list[k++] = e;
				e = e.preorder;
			}
		}
		
		if (k > _maxSize) _maxSize = k;
		
		for (i in 0...k)
		{
			e = list[i];
			if (e._flags & (E.BIT_GHOST | E.BIT_SKIP_DRAW | E.BIT_MARK_FREE | E.BIT_SKIP_UPDATE) == 0)
				e.onDraw(alpha);
		}
	}
	
	function freeEntities()
	{
		#if verbose
		var freeCount = 0;
		#end

		//free marked entities; this is done as a last step to prevent rebuilding the entities array
		var e = child, p, next;
		while (e != null)
		{
			next = e.preorder;
			
			if (e._flags & E.BIT_MARK_FREE > 0)
			{
				next = e.nextSubtree();
				
				//disconnect subtree rooted at this entity
				//force removal by setting commit flag
				if (e.parent != null) e.parent.remove(e);
				
				//bottom-up deconstruction (calls onFree() on all descendants)
				EntitySystem.freeEntity(e);
				
				#if verbose
				freeCount++;
				#end
			}
			
			e = next;
		}
		
		#if verbose
		if (freeCount > 0)
		{
			if (freeCount == 1)
				L.d('freed one subtree', "es");
			else
				L.d('freed $freeCount subtrees', "es");
		}
		#end
	}
}