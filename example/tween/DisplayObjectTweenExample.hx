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
import de.polygonal.core.math.random.Random;
import de.polygonal.core.Root;
import de.polygonal.core.time.Timeline;
import de.polygonal.core.tween.DisplayObjectTween;
import de.polygonal.core.tween.ease.Ease;
import de.polygonal.core.tween.Tween;
import de.polygonal.core.tween.TweenEvent;
import flash.display.Shape;
import flash.Lib;

typedef Flags = DisplayObjectTween;

class DisplayObjectTweenExample implements IObserver
{
	inline static var RADIUS = 10;
	
	static function main()
	{
		Root.init();
		
		//required by Tween class
		Timeline.bindToTimebase(true);
		
		Timeline.POOL_SIZE = 10000;
		
		new DisplayObjectTweenExample();
	}
	
	public function new()
	{
		for (i in 0...100)
		{
			var shape = new Shape();
			shape.name = 'shape_' + i;
			shape.graphics.beginFill(Std.int(Math.random() * 0xffffff), .5);
			shape.graphics.drawCircle(0, 0, RADIUS);
			shape.graphics.endFill();
			Lib.current.addChild(shape);
			shape.x = randX();
			shape.y = randY();
			
			//or use Tween.create(...)
			var tweenX = new DisplayObjectTween(shape.name + 'x', shape, Flags.X, Ease.PowOut(2), randX(), randTime()).run();
			var tweenY = new DisplayObjectTween(shape.name + 'y', shape, Flags.Y, Ease.PowOut(2), randY(), randTime()).run();
			var tweenScale = new DisplayObjectTween(shape.name + 's', shape, Flags.SCALEX | Flags.SCALEY, Ease.PowOut(2), randScale(), randTime()).run();
			tweenX.attach(this, TweenEvent.FINISH);
			tweenY.attach(this, TweenEvent.FINISH);
			tweenScale.attach(this, TweenEvent.FINISH);
		}
	}
	
	public function update(type:Int, source:IObservable, userData:Dynamic):Void 
	{
		var tween:Tween = cast source;
		
		var key = tween.getKey();
		
		if (key.indexOf('x') != -1)
			tween.to(randX()).duration(randTime()).run();
		else
		if (key.indexOf('y') != -1)
			tween.to(randY()).duration(randTime()).run();
		else	
		if (key.indexOf('s') != -1)
			tween.to(randScale()).duration(randTime()).run();
	}
	
	function randX()
	{
		return Random.frandRange(RADIUS, 800 - RADIUS);
	}
	
	function randY()
	{
		return Random.frandRange(RADIUS, 600 - RADIUS);
	}
	
	function randTime()
	{
		return Random.frandRange(.2, 2);
	}
	
	function randScale()
	{
		return Random.frandRange(1, 3);
	}
}