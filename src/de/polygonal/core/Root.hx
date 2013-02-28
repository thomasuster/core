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
package de.polygonal.core;

import de.polygonal.core.fmt.Sprintf;
import de.polygonal.core.util.Assert;
import haxe.PosInfos;

/**
 * <p>The root of an application.</p>
 */
class Root
{
	/**
	 * The root logger; initialized when calling <em>Root.init()</em>.
	 */
	#if log
	public static var log(default, null):de.polygonal.core.log.Log = null;
	#end
	
	/**
	 * Short for <em>Root.log.debug()</em>.<br/>
	 * Example:<br/>
	 * <pre class="prettyprint">
	 * using de.polygonal.core.Root;
	 * "Hello World!".debug();
	 * </pre>
	 */
	inline public static function debug(x:Dynamic):Void
	{
		#if log
			#if debug
			D.assert(log != null, 'call Root.initLog() first');
			#end
		log.debug(x);
		#end
	}
	
	/**
	 * Short for <em>Root.log.info()</em>.<br/>
	 * Example:<br/>
	 * <pre class="prettyprint">
	 * using de.polygonal.core.Root;
	 * "Hello World!".info();
	 * </pre>
	 */
	inline public static function info(x:Dynamic, ?posInfos:PosInfos):Void
	{
		#if log
			#if debug
			D.assert(log != null, 'call Root.initLog() first');
			#end
		log.info(x, posInfos);
		#end
	}
	
	/**
	 * Short for <em>Root.log.warn()</em>.<br/>
	 * Example:<br/>
	 * <pre class="prettyprint">
	 * using de.polygonal.core.Root;
	 * "Hello World!".warn();
	 * </pre>
	 */
	inline public static function warn(x:Dynamic):Void
	{
		#if log
			#if debug
			D.assert(log != null, 'call Root.initLog() first');
			#end
		log.warn(x);
		#end
	}
	
	/**
	 * Short for <em>Root.log.error()</em>.<br/>
	 * Example:<br/>
	 * <pre class="prettyprint">
	 * using de.polygonal.core.Root;
	 * "Hello World!".error();
	 * </pre>
	 */
	inline public static function error(x:Dynamic, ?posInfos:PosInfos):Void
	{
		#if log
			#if debug
			D.assert(log != null, 'call Root.initLog() first');
			#end
		log.error(x, posInfos);
		#end
	}
	
	#if flash
	/**
	 * Returns true if this swf is a remote-swf.<br/>
	 * <warn>Flash only</warn>
	 */
	public static function isRemote():Bool
	{
		return flash.Lib.current.stage.loaderInfo.url.indexOf('file:///') == -1;
	}
	
	/**
	 * Returns the value of the FlashVar with name <code>key</code> or null if the FlashVar does not exist.<br/>
	 * <warn>Flash only</warn>
	 */
	public static function getFlashVar(key:String):String
	{
		try
		{
			return untyped flash.Lib.current.stage.loaderInfo.parameters[key];
		}
		catch (error:Dynamic) {}
		return null;
	}
	#end
	
	/**
	 * Initializes the root logger object.
	 * @param handlers additional log handler objects that get attached to <em>Root.log</em> upon initialization.
	 * @param keepNativeTrace if true, do not override native trace output. Default is false.
	 */
	#if log
	public static function initLog(handlers:Array<de.polygonal.core.log.LogHandler> = null, keepNativeTrace = false)
	#else
	public static function initLog(handlers:Array<Dynamic> = null, keepNativeTrace = false)
	#end
	{
		#if !no_traces
			#if log
			var nativeTrace = function(v:Dynamic, ?infos:haxe.PosInfos) {};
			if (keepNativeTrace) nativeTrace = haxe.Log.trace;
			
			de.polygonal.core.log.Log.globalHandler = [];
			de.polygonal.core.log.Log.globalHandler.push(
			#if flash
			new de.polygonal.core.log.handler.TraceHandler()
			#elseif cpp
			new de.polygonal.core.log.handler.FileHandler('hxcpp_log.txt')
			#elseif js
			new de.polygonal.core.log.handler.ConsoleHandler()
			#end
			);
			
			if (handlers != null)
			{
				for (handler in handlers)
					de.polygonal.core.log.Log.globalHandler.push(handler);
			}
			log = de.polygonal.core.log.Log.getLog(Root);
			
			haxe.Log.trace = function(x:Dynamic, ?posInfos:haxe.PosInfos)
			{
				if (posInfos.customParams != null)
				{
					if (~/%(([+\- #0])*)?((\d+)|(\*))?(\.(\d?|(\*)))?[hlL]?[bcdieEfgGosuxX]/g.match(x))
						x = Sprintf.format(Std.string(x), posInfos.customParams);
					else
						x = x + ',' + posInfos.customParams.join(',');
				}
				Root.log.debug(x, posInfos);
				nativeTrace(x, posInfos);
			}
			trace('log initialized.');
			#end
		#end
	}
}