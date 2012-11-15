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
package;

import de.polygonal.core.event.IObservable;
import de.polygonal.core.event.IObserver;
import de.polygonal.core.Root;
import de.polygonal.core.time.Timeline;
import de.polygonal.core.tween.ease.Ease;
import de.polygonal.core.tween.Tween;
import de.polygonal.core.tween.TweenEvent;
import de.polygonal.core.tween.TweenTarget;

class BasicTweenExample implements IObserver
{
	static function main()
	{
		Root.init();
		
		//required by Tween class
		Timeline.bindToTimebase(true);
		
		new BasicTweenExample();
	}
	
	public function new()
	{
		var target = new TweenedObject();
		
		var tween = new Tween(target, Ease.PowOut(2), 100, 2.5);
		
		//attach to TweenEvent-updates
		tween.attach(this); 
		
		//run tween
		tween.run();
	}
	
	public function update(type:Int, source:IObservable, userData:Dynamic):Void 
	{
		var progress:Float = cast(source, Tween).getProgress(); //[0,1]
		trace('update: %-10s, value: %.3f progress: %.3f', TweenEvent.getName(type)[0], userData, progress);
	}
}

class TweenedObject implements TweenTarget
{
	var _value = 0.;
	
	public function new() {}
	
	public function get():Float
	{
		return _value;
	}
	
	public function set(x:Float):Void
	{
		_value = x;
	}
}