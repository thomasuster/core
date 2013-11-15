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
package de.polygonal.core.screen;

import de.polygonal.core.es.Entity;
import de.polygonal.core.time.Interval;

@:access(de.polygonal.core.screen.Screen)
class ScreenTransition extends Entity
{
	var _a:Screen;
	var _b:Screen;
	var _effect:ScreenTransitionEffect<Dynamic>;
	
	var _interval:Interval;
	var _phase:Int;
	
	public function new()
	{
		super();
		
		_interval = new Interval();
		tick = false;
	}
	
	override function onFree()
	{
		_a = null;
		_b = null;
		_effect = null;
		_interval = null;
	}
	
	/**
	 * Applies a transition effect to screen a and b
	 */
	public function run<T:Screen>(effect:ScreenTransitionEffect<T>, a:T, b:T)
	{
		_effect = effect;
		_a = a;
		_b = b;
		
		var mode = effect.getMode();
		
		var duration = effect.getDuration();
		
		if (duration == 0)
		{
			if (a != null)
			{
				a.onHideStart(b);
				a.onHideEnd(b);
			}
			b.onShowStart(a);
			b.onShowEnd(a);
			return;
		}
		
		tick = true;
		
		if (mode == ScreenTransitionMode.Sequential) duration /= 2;
		_interval.duration = duration;
		
		switch (_effect.getMode()) 
		{
			case Sequential:
				_phase = 0;
				if (_a == null)
				{
					b.onShowStart(null);
					_effect.onStart(_a, b);
				}
				else
				{
					_a.onHideStart(b);
					_effect.onStart(_a, b);
				}
			
			case Simultaneous:
				if (_a != null) _a.onHideStart(b);
				b.onShowStart(_a);
				_effect.onStart(_a, b);
		}
	}
	
	override function onTick(dt:Float)
	{
		switch (_effect.getMode()) 
		{
			case Sequential:
				var alpha = _interval.alpha;
				_interval.advance(dt);
				if (_phase == 0)
				{
					if (alpha >= 1)
					{
						if (_a == null)
						{
							tick = false;
							
							_effect.onAdvance(_b, 1, 1);
							_effect.onComplete(_b);
							_b.onShowEnd(null);
							_b = null;
							_effect = null;
							return;
						}
						
						_effect.onAdvance(_a, 1, -1);
						_effect.onComplete(_a);
						
						_phase = 1;
						_interval.reset();
						
						_a.onHideEnd(_b);
						_b.onShowStart(_a);
					}
					else
					{
						if (_a != null)
							_effect.onAdvance(_a, alpha, -1);
						else
							_effect.onAdvance(_b, alpha, 1);
					}
				}
				else
				if (_phase == 1)
				{
					if (alpha >= 1)
					{
						tick = false;
						
						_effect.onAdvance(_b, 1, 1);
						_effect.onComplete(_b);
						_b.onShowEnd(_a);
						_a = null;
						_b = null;
						_effect = null;
					}
					else
						_effect.onAdvance(_b, alpha, 1);
				}
			
			case Simultaneous:
				var alpha = _interval.alpha;
				_interval.advance(dt);
				if (alpha >= 1)
				{
					tick = false;
					if (_a != null)
					{
						_effect.onAdvance(_a, 1, -1);
						_effect.onComplete(_a);
						_a.onHideEnd(_b);
					}
					_effect.onAdvance(_b, 1, 1);
					_effect.onComplete(_b);
					_b.onShowEnd(_a);
					_a = null;
					_b = null;
					_effect = null;
					return;
				}
				if (_a != null) _effect.onAdvance(_a, alpha, -1);
				_effect.onAdvance(_b, alpha, 1);
		}
	}
}