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

import de.polygonal.core.screen.ScreenTransition.ScreenTransitionMode;

typedef ScreenTransitionEffect<T:Screen> =
{
	function onStart(a:T, b:T):Void;
	
	/**
	 * Called while the transition effect updates screen.
	 * @param x the progress in the range [0,1]
	 * @param direction > 0 if screen is shown, < 0 if screen is hidden
	 */
	function onAdvance(screen:T, progress:Float, state:Int):Void;
	
	/**
	 * Called once the transition effect is complete.
	 * @param half true if the transition is halfway through (sequential transitions only).
	 */
	function onComplete(screen:T, half:Bool):Void;
	
	/**
	 * The transition mode.
	 */
	function getMode():ScreenTransitionMode;
	
	/**
	 * The transition effect duration in seconds.
	 */
	function getDuration():Float;
}