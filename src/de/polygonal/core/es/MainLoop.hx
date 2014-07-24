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
	public static var instance(get_instance, never):MainLoop;
	static function get_instance():MainLoop return mInstance == null ? (mInstance = new MainLoop()) : mInstance;
	static var mInstance:MainLoop = null;
	
	public var paused = false;
	
	var mStack:Array<E>;
	var mTop:Int;
	var mScratchList:Vector<E>;
	var mMaxSize:Int;
	
	public function new()
	{
		super("MainLoop");
		
		Timebase.init();
		Timebase.attach(this);
		Timeline.init();
		
		mScratchList = new Vector<E>(ES.MAX_SUPPORTED_ENTITIES);
		mMaxSize = 0;
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
			//1) process scheduled events
			Timeline.tick();
			
			//2) advance entities
			var dt:Float = userData;
			propagateTick(dt);
			
			//3) dispatch buffered messages
			EntitySystem.dispatchMessages();
			
			//4) free marked entities
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
				var k = mMaxSize;
				mMaxSize = 0;
				var list = mScratchList;
				for (i in 0...k) list[i] = null;
			}
		}
	}
	
	function propagateTick(dt:Float)
	{
		var list = mScratchList;
		var k = 0;
		var e = child;
		while (e != null)
		{
			if (e.mFlags & E.BIT_SKIP_SUBTREE != 0)
			{
				e = e.nextSubtree();
				if (e != null)
				{
					list[k++] = e;
					e = e.preorder;
				}
			}
			else
			{
				list[k++] = e;
				e = e.preorder;
			}
		}
		
		if (k > mMaxSize) mMaxSize = k;

		for (i in 0...k)
		{
			e = list[i];
			if (e.parent != null && e.mFlags & (E.BIT_GHOST | E.BIT_SKIP_TICK | E.BIT_MARK_FREE | E.BIT_SKIP_UPDATE) == 0)
				e.onTick(dt);
		}
	}
	
	function propagateDraw(alpha:Float)
	{
		var list = mScratchList;
		var k = 0;
		var e = child;
		while (e != null)
		{
			if (e.mFlags & E.BIT_SKIP_SUBTREE != 0)
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
		
		if (k > mMaxSize) mMaxSize = k;
		
		for (i in 0...k)
		{
			e = list[i];
			if (e.mFlags & (E.BIT_GHOST | E.BIT_SKIP_DRAW | E.BIT_MARK_FREE | E.BIT_SKIP_UPDATE) == 0)
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
			
			if (e.mFlags & E.BIT_MARK_FREE > 0)
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