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
package de.polygonal.core.log.handler;

import de.polygonal.core.log.LogHandler;
import flash.display.DisplayObjectContainer;
import flash.events.Event;
import flash.Lib;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFormat;

using de.polygonal.ds.BitFlags;

#if !flash
'The TextFieldHandler class is only available for flash'
#end

class TextFieldHandler extends LogHandler
{
	public var tf(default, null):TextField;
	
	public function new(?tf:TextField, ?parent:DisplayObjectContainer)
	{
		super();
		
		if (tf != null)
			this.tf = tf;
		else
		{
			this.tf = tf = new TextField();
			tf.defaultTextFormat = new TextFormat('Arial', 10);
			tf.autoSize = TextFieldAutoSize.LEFT;
			flash.Lib.current.addChild(tf);
		}
		
		tf.name = 'loghandler';
		flash.Lib.current.addEventListener(Event.ADDED, onAdded);
	}
	
	override function output(message:String):Void
	{
		tf.appendText(message + '\n');
		tf.scrollV = tf.maxScrollV;
	}
	
	function onAdded(e:Event):Void
	{
		if (tf.parent != null)
		{
			if (tf.parent.numChildren > 1)
			{
				var topmost = tf.parent.getChildAt(tf.parent.numChildren - 1);
				if (tf.parent.getChildIndex(tf) < tf.parent.getChildIndex(topmost))
					tf.parent.swapChildren(tf, topmost);
			}
		}
	}
}