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
 * Copyright (c) 2009 Michael Baczynski, http://www.polygonal.de
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
package de.polygonal.core.sys;

import de.polygonal.core.event.IObservable;
import de.polygonal.core.sys.Entity;
import de.polygonal.core.time.Timebase;
import de.polygonal.core.time.TimebaseEvent;
import de.polygonal.core.time.Timeline;
import haxe.Timer;

class MainLoop extends Entity
{
	public var tickTimeSeconds:Float;
	public var drawTimeSeconds:Float;
	
	public var paused:Bool = true;
	
	var _tickTime:Float;
	var _drawTime:Float;
	
	public function new()
	{
		super();
		Timebase.get().attach(this);
	}
	
	override function onFree():Void 
	{
		Timebase.get().detach(this);
	}
	
	override public function update(type:Int, source:IObservable, userData:Dynamic):Void
	{
		switch (type)
		{
			case TimebaseEvent.TICK:
				tickTimeSeconds = 0;
				
				#if (!no_traces)
				//identify tick step
				var log = de.polygonal.core.Root.log;
				if (log != null)
					for (handler in log.getLogHandler())
						handler.setPrefix(de.polygonal.core.fmt.Sprintf.format('t%03d', [Timebase.get().processedTicks % 1000]));
				#end
				
				if (paused) return;
				
				tickTimeSeconds = _tickTime;
				_tickTime = Timer.stamp();
				
				Timeline.get().advance();
				commit();
				tick(userData);
				
				_tickTime = Timer.stamp() - _tickTime;
				
				#if verbose
				var s = Entity.printTopologyStats();
				if (s != null) de.polygonal.core.Root.debug(s);
				#end
			
			case TimebaseEvent.RENDER:
				drawTimeSeconds = 0;
				
				if (paused) return;
				
				drawTimeSeconds = _drawTime;
				_drawTime = Timer.stamp();
				
				#if (!no_traces)
				//identify draw step
				var log = de.polygonal.core.Root.log;
				if (log != null)
					for (handler in log.getLogHandler())
						handler.setPrefix(de.polygonal.core.fmt.Sprintf.format('r%03d', [Timebase.get().processedFrames % 1000]));
				#end
				
				draw(userData);
				
				_drawTime = Timer.stamp() - _drawTime;
		}
	}
}