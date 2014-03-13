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
package de.polygonal.core.screen;

import de.polygonal.core.es.Entity;

class Screen extends Entity
{
	/**
	 * Bottommost 0, above 1;
	 */
	public var zIndex:Int;
	
	function new(name:String = null)
	{
		if (name == null) name = Type.getClassName(Type.getClass(this));
		super(name);
		exposeName();
	}
	
	override public function toString():String
	{
		return super.toString() + ', zIndex=$zIndex';
	}
	
	override function set_name(value:String):String
	{
		if (_name != null)
			throw "screen name is immutable";
		return super.set_name(value);
	}
	
	/**
	 * A transition effect starts to show this screen and hide the other one ((e.g. a fade-in begins).
	 * Invoked by ScreenTransition.
	 */
	function onShowStart(other:Screen):Void {}
	
	/**
	 * Called after a transition effect has shown this screen and has hidden other ((e.g. a fade-in complete).
	 * Invoked by ScreenTransition.
	 */
	function onShowEnd(other:Screen):Void {}
	
	/**
	 * Called once a transition effect starts to hide this screen and show other ((e.g. a fade-out begins).
	 * Invoked by ScreenTransition.
	 */
	function onHideStart(other:Screen):Void {}
	
	/**
	 * Called after a transition effect has hidden this screen and has shown other ((e.g. a fade-out complete).
	 * Invoked by ScreenTransition.
	 */
	function onHideEnd(other:Screen):Void {}
}