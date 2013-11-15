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
import de.polygonal.core.es.EntitySystem;
import de.polygonal.core.util.Assert;
import haxe.ds.StringMap;

class ScreenManager extends Entity
{
	var _transitionEffectLookup:StringMap<ScreenTransitionEffect<Dynamic>>;
	var _currentScreen:Screen;
	
	public function new()
	{
		super();
		
		_transitionEffectLookup = new StringMap();
		_transitionEffectLookup.set("null", new NullTransition());
		add(ScreenTransition);
	}
	
	override function onFree()
	{	
		_transitionEffectLookup = null;
		_currentScreen = null;
	}
	
	public function show(screenName:String)
	{
		var a = _currentScreen;
		
		var tmp = EntitySystem.lookupByName(screenName);
		D.assert(tmp != null && tmp.length == 1, 'no screen with name $screenName found');
		var b:Screen = cast tmp[0];
		
		_currentScreen = b;
		
		var effect = lookupEffect(a, b);
		childByType(ScreenTransition).run(effect, a, b);
	}
	
	public function defineDefaultTransitionEffect<T:Screen>(style:ScreenTransitionEffect<T>)
	{
		_transitionEffectLookup.set("default", style);
	}
	
	public function defineTransition<T:Screen>(a:T, b:T, effect:Class<ScreenTransitionEffect<T>>, ?reverseEffect:Class<ScreenTransitionEffect<T>>)
	{
		_transitionEffectLookup.set(getKey(a, b), cast effect);
		if (reverseEffect != null) _transitionEffectLookup.set(getKey(b, a), cast reverseEffect);
	}
	
	function lookupEffect(a:Screen, b:Screen):ScreenTransitionEffect<Dynamic>
	{
		var effect = _transitionEffectLookup.get(getKey(a, b));
		
		if (effect == null) //no effect registered for this screen pair
			effect = _transitionEffectLookup.get("default"); //fallback to default effect
			
		if (effect == null) //skip transition effect
			effect = _transitionEffectLookup.get("null");
			
		return effect;
	}
	
	function getKey(a:Screen, b:Screen):String
		return (a == null ? "null" : a.name) + (b == null ? "null" : b.name);
}

private class NullTransition implements ScreenTransitionEffect<Dynamic>
{
	public function new() {}
	
	public function onStart(a:Screen, b:Screen):Void {}
	
	public function onAdvance(screen:Screen, progress:Float, direction:Int):Void {}
	
	public function onComplete(screen:Screen):Void {}
	
	public function getMode():ScreenTransitionMode return ScreenTransitionMode.Simultaneous;
	
	public function getDuration():Float return 0;
}