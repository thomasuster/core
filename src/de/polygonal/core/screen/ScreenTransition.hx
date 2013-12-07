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
import de.polygonal.core.fmt.StringUtil;
import de.polygonal.core.time.Interval;
import de.polygonal.Printf;
import de.polygonal.core.util.Assert;

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
	
	override function onAdd()
	{
		D.assert(parent.is(ScreenManager));
	}
	
	override function onFree()
	{
		_a = null;
		_b = null;
		_effect = null;
		_interval = null;
	}
	
	/**
	 * Applies a transition effect to go from screen a to b.
	 */
	public function run<T:Screen>(effect:ScreenTransitionEffect<T>, a:T, b:T)
	{
		log("run", a, b);
		
		_effect = effect;
		_a = a;
		_b = b;
		
		var mode = effect.getMode();
		
		var duration = effect.getDuration();
		
		if (duration == 0)
		{
			if (a != null)
			{
				log("onHideStart", a, b);
				a.onHideStart(b);
				log("onHideEnd", a, b);
				a.onHideEnd(b);
			}
			
			log("onShowStart", a, b);
			b.onShowStart(a);
			log("onShowEnd", a, b);
			b.onShowEnd(a);
			
			parent.as(ScreenManager).onTransitionComplete();
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
					log("onShowStart", _a, b);
					b.onShowStart(null);
					_effect.onStart(_a, b);
				}
				else
				{
					log("onHideStart", _a, b);
					_a.onHideStart(b);
					_effect.onStart(_a, b);
				}
			
			case Simultaneous:
				if (_a != null)
				{
					log("onHideStart", _a, b);
					_a.onHideStart(b);
				}
				
				log("onShowStart", _a, b);
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
							_effect.onComplete(_b, false);
							
							log("onShowEnd", null, _b);
							_b.onShowEnd(null);
							
							_b = null;
							_effect = null;
							
							parent.as(ScreenManager).onTransitionComplete();
							return;
						}
						
						_effect.onAdvance(_a, 1, -1);
						_effect.onComplete(_a, true);
						
						_phase = 1;
						_interval.reset();
						
						log("onHideEnd", _a, _b);
						_a.onHideEnd(_b);
						
						log("onShowStart", _a, _b);
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
						_effect.onComplete(_b, false);
						
						log("onShowEnd", _a, _b);
						_b.onShowEnd(_a);
						_a = null;
						_b = null;
						_effect = null;
						
						parent.as(ScreenManager).onTransitionComplete();
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
						_effect.onComplete(_a, false);
						
						log("onHideEnd", _a, _b);
						_a.onHideEnd(_b);
					}
					_effect.onAdvance(_b, 1, 1);
					_effect.onComplete(_b, false);
					
					log("onShowEnd", _a, _b);
					_b.onShowEnd(_a);
					_a = null;
					_b = null;
					_effect = null;
					
					parent.as(ScreenManager).onTransitionComplete();
					return;
				}
				if (_a != null) _effect.onAdvance(_a, alpha, -1);
				_effect.onAdvance(_b, alpha, 1);
		}
	}
	
	function log(s:String, a:Screen, b:Screen)
	{
		var nameA = "none";
		if (a != null) nameA = StringUtil.ellipsis('${a.name}[${a.zIndex}]', 20, 0);
		
		var nameB = "none";
		if (b != null) nameB = StringUtil.ellipsis('${b.name}[${b.zIndex}]', 20, 0);
		
		L.d(Printf.format("%-12s %-30s => %-30s", [s, nameA, nameB]), "screen");
	}
}