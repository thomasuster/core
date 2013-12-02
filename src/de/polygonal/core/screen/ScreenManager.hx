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
import de.polygonal.core.screen.ScreenTransition;
import de.polygonal.core.util.Assert;
import de.polygonal.core.util.ClassUtil;
import de.polygonal.ds.LinkedQueue;
import de.polygonal.ds.LinkedStack;
import haxe.ds.StringMap;

private class ScreenPair
{
	public var a:Screen;
	public var b:Screen;
	
	public function new(a:Screen, b:Screen)
	{
		this.a = a;
		this.b = b;
	}
}


class ScreenManager extends Entity
{
	var _transitionEffectLookup:StringMap<ScreenTransitionEffect<Dynamic>>;
	
	var _screenStack:LinkedStack<Screen>;
	
	var _transitionQue:LinkedQueue<ScreenPair>;
	var _transitionInProgress:Bool;
	
	public function new()
	{
		super(ScreenManager.ENTITY_NAME);
		exposeName();
		
		_transitionEffectLookup = new StringMap();
		_transitionEffectLookup.set("null",
		{
			onStart: function(a:Screen, b:Screen):Void {},
			onAdvance: function(screen:Screen, progress:Float, direction:Int):Void {},
			onComplete: function(screen:Screen):Void {},
			getMode: function() return ScreenTransitionMode.Simultaneous,
			getDuration: function() return 0
		});
		
		add(ScreenTransition);
		
		_screenStack = new LinkedStack<Screen>();
		_transitionQue = new LinkedQueue<ScreenPair>();
	}
	
	override function onFree()
	{
		_transitionEffectLookup = null;
	}
	
	function processQue()
	{
		if (_transitionInProgress) return;
		
		if (_transitionQue.size() > 0)
		{
			var pair = _transitionQue.dequeue();
			_transitionInProgress = true;
			
			var intermediate = !_transitionQue.isEmpty();
			
			var effect = lookupEffect(pair.a, pair.b);
			childByType(ScreenTransition).run(effect, pair.a, pair.b);
		}
	}
	
	public function onTransitionComplete()
	{
		_transitionInProgress = false;
		processQue();
	}
	
	public function switchTo(screen:Screen)
	{
		var a = _screenStack.pop();
		var b = screen;
		
		b.zIndex = _screenStack.size();
		
		if (b.parent == null) add(b);
		_screenStack.push(screen);
		
		_transitionQue.enqueue(new ScreenPair(a, b));
		processQue();
	}
	
	public function hasPendingTransitions():Bool
	{
		return _transitionQue.size() > 0;
	}
	
	public function push(screen:Screen)
	{
		var a = _screenStack.isEmpty() ? null : _screenStack.top();
		var b = screen;
		
		b.zIndex = _screenStack.size();
		_screenStack.push(b);
		if (b.parent == null) add(b);
		
		_transitionQue.enqueue(new ScreenPair(a, b));
		processQue();
	}
	
	public function pop(count:Int)
	{
		if (count < 0) count = _screenStack.size() - 1;
		
		for (i in 0...count)
		{
			var a = _screenStack.pop();
			var b = _screenStack.top();
			_transitionQue.enqueue(new ScreenPair(a, b));
		}
		
		processQue();
	}
	
	public function defineDefaultTransitionEffect<T:Screen>(style:ScreenTransitionEffect<T>)
	{
		_transitionEffectLookup.set("default", style);
	}
	
	public function defineTransition<A:Screen, B:Screen>(a:Class<A>, b:Class<B>, style:ScreenTransitionEffect<A>, ?reverseStyle:ScreenTransitionEffect<B>)
	{
		var as:String = Type.getClassName(a);
		
		var keyA = a == null ? "null" : Type.getClassName(a);
		var keyB = b == null ? "null" : Type.getClassName(b);
		
		_transitionEffectLookup.set(keyA + keyB, style);
		if (reverseStyle != null) _transitionEffectLookup.set(keyB + keyA, reverseStyle);
	}
	
	function lookupEffect<T:Screen>(a:T, b:T):ScreenTransitionEffect<T>
	{
		var key = "";
		key += a == null ? "null" : a.name;
		key += b == null ? "null" : b.name;
		
		var effect = _transitionEffectLookup.get(key);
		
		if (effect == null)
		{
			if (_transitionEffectLookup.exists(key))
				effect = _transitionEffectLookup.get("null"); //null transition
			else
			{
				effect = _transitionEffectLookup.get("default"); //fallback to default effect
				if (effect == null) effect = _transitionEffectLookup.get("null");
			}
		}
		
		return effect;
	}
}