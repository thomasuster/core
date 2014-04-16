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
package de.polygonal.core.codec;

import haxe.crypto.BaseCode;
import haxe.io.Bytes;
import haxe.io.BytesData;

/**
 * <p>A Base64 encoder/decoder.</p>
 */
class Base64
{
	static var BASE64_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
	static var coder = new BaseCode(Bytes.ofString(BASE64_CHARS));
	
	/**
	 * Encodes a <em>BytesData</em> object into a string in Base64 notation.
	 * @param source the source data.
	 * @param breakLines if true, breaks lines every <code>maxLineLength</code> characters.<br/>
	 * Disabling this behavior violates strict Base64 specification, but makes the encoding faster.
	 * @param maxLineLength the maximum line length of the output. Default is 76.
	 */
	inline public static function encode(source:BytesData, breakLines = false, maxLineLength = 76):String
	{
		return encodeBytes(Bytes.ofData(source), breakLines, maxLineLength);
	}
	
	/**
	 * Shortcut for encoding a string into a string in Base64 notation.
	 * @param source the source data.
	 * @param breakLines if true, breaks lines every <code>maxLineLength</code> characters.<br/>
	 * Disabling this behavior violates strict Base64 specification, but makes the encoding faster.
	 * @param maxLineLength the maximum line length of the output. Default is 76.
	 */
	inline public static function encodeString(source:String, breakLines = false, maxLineLength = 76):String
	{
		return encodeBytes(Bytes.ofString(source), breakLines, maxLineLength);
	}
	
	/**
	 * Decodes a Base64 encoded string into a <em>BytesData</em> object.
	 * @param source the source data.
	 * @param breakLines if true, removes all newline (\n) characters from the <code>source</code> string before
	 * decoding it.<br/>
	 * Use this flag if the source was encoded with <code>breakLines</code> = true.
	 * Default is false.
	 */
	inline public static function decode(source:String, breakLines = false):BytesData
	{
		return decodeBytes(source, breakLines).getData();
	}
	
	/**
	 * Shortcut for decoding a Base64 encoded string directly into a string.
	 * @param source the source data.
	 * @param breakLines if true, removes all newline (\n) characters from the <code>source</code> string before
	 * decoding it.<br/>
	 * Use this flag if the source was encoded with <code>breakLines</code> = true.
	 * Default is false.
	 */
	inline public static function decodeString(source:String, breakLines = false):String
	{
		var bytes = decodeBytes(source, breakLines);
		return bytes.getString(0, bytes.length);
	}
	
	inline private static function decodeBytes(source:String, breakLines = false)
	{
		if (breakLines)
			source = source.split("\n").join("");
		
		var padding = source.indexOf("=");
		if (padding != -1)
			source = source.substring(0, padding);
		
		return coder.decodeBytes(Bytes.ofString(source));
	}
	
	inline static function pad(str:String)
	{
		return str + switch(str.length % 4)
		{
			case 3:  "===";
			case 2:  "==";
			case 1:  "=";
			default: "";
		};
	}
	
	inline static function split(str:String, lineLength:Int)
	{
		var lines = [];
		while (str.length > lineLength)
		{
			lines.push(str.substring(0, lineLength));
			str = str.substring(lineLength);
		}
		return lines.join("\n");
	}
	
	private static function encodeBytes(source:Bytes, breakLines = false, maxLineLength = 76):String
	{
		var bytes = coder.encodeBytes(source);
		var result = pad(bytes.getString(0, bytes.length));
		return breakLines ? split(result, maxLineLength) : result;
	}
}