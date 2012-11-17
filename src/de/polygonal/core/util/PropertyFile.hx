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
package de.polygonal.core.util;

import de.polygonal.core.fmt.ASCII;
import haxe.rtti.CType.TypeTree;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
#end

class PropertyFile
{
	#if macro
	@:macro public static function build(url:String, staticFields:Bool):Array<Field>
	{
		Context.registerModuleDependency(Std.string(Context.getLocalClass()), url);
		var pos = Context.currentPos();
		
		var fields = Context.getBuildFields();
		var assign = new Array<Expr>();
		
		var access = [APublic];
		if (staticFields)
		{
			access.push(AStatic);
			access.push(AInline);
		}
		
		var map = parse(neko.io.File.getContent(url));
		for (key in map.keys())
		{
			var val = map.get(key);
			
			var c = null, n:String, p = [];
			if (val.indexOf(',') != -1)
			{
				var arrExpr = [];
				var arrType;
				var tmp:Array<String> = val.split(',');
				
				if (tmp[0].indexOf('.') != -1)
				{
					for (i in tmp) arrExpr.push({expr: EConst(CFloat(Std.string(Std.parseFloat(i)))), pos: pos});
					arrType = 'Float';
				}
				else
				{
					var int = Std.parseInt(tmp[0]);
					if (int == null)
					{
						for (i in tmp) arrExpr.push({expr: EConst(CString(i)), pos: pos});
						arrType = 'String';
					}
					else
					{
						for (i in tmp) arrExpr.push({expr: EConst(CInt(Std.string(Std.parseInt(i)))), pos: pos});
						arrType = 'Int';
					}
				}
				
				n = 'Array';
				c = EArrayDecl(arrExpr);
				p = [TPType(TPath({sub: null, name: arrType, pack: [], params: []}))];
			}
			else
			if (val.indexOf('.') != -1)
			{
				if (Math.isNaN(Std.parseFloat(val)))
				{
					c = EConst(CString(val));
					n = 'String';
				}
				else
				{
					c = EConst(CFloat(val));
					n = 'Float';
				}
			}
			else
			if (val == 'true' || val == 'false')
			{
				c = EConst(CIdent(val));
				n = 'Bool';
			}
			else
			{
				var int = Std.parseInt(val);
				if (int == null)
				{
					c = EConst(CString(val));
					n = 'String';
				}
				else
				{
					c = EConst(CInt(val));
					n = 'Int';
				}
			}
			
			if (c == null)
				Context.error('invalid field type', Context.currentPos());
			
			if (staticFields)
				fields.push({name: key, doc: null, meta: [], access: access, kind: FVar(TPath({pack: [], name: n, params: p, sub: null}), {expr: c, pos: pos}), pos: pos});
			else
			{
				fields.push({name: key, doc: null, meta: [], access: access, kind: FVar(TPath({pack: [], name: n, params: p, sub: null})), pos: pos});
				assign.push({expr: EBinop(Binop.OpAssign, {expr: EConst(CIdent(key)), pos: pos}, {expr: c, pos: pos}), pos:pos});
			}
		}
		
		if (!staticFields) fields.push({name: 'new', doc: null, meta: [], access: [APublic], kind: FFun({args: [], ret: null, expr: {expr: EBlock(assign), pos:pos}, params: []}), pos: pos});
		return fields;
	}
	#end
	
	public static function parse(s:String):Hash<String>
	{
		try
		{
			var a = [];
			var b = '';
			var i = 0;
			while (i < s.length)
			{
				var c = s.charCodeAt(i);
				
				//skip comment?
				if (c == ASCII.NUMBERSIGN || c == ASCII.EXCLAM)
				{
					i++;
					var t = '';
					while (s.charCodeAt(i) != ASCII.NEWLINE)
					{
						t += s.charAt(i);
						i++;
					}
					continue;
				}
				
				//skip whitespace?
				if (ASCII.isWhite(c))
				{
					if (b != '')
					{
						a.push(b);
						b = '';
					}
					i++;
					continue;
				}
				
				if (c == ASCII.COLON || c == ASCII.EQUAL)
				{
					if (b != '')
					{
						a.push(b);
						b = '';
					}
					i++;
					continue;
				}
				
				b += s.charAt(i++);
			}
			
			if (b != '') a.push(b);
			
			var pairs = new Hash();
			var next = 0;
			for (i in 0...a.length >> 1)
			{
				var key = a[next++];
				var val = a[next++];
				pairs.set(key, val);
			}
			return pairs;
		}
		catch (unknown:Dynamic)
		{
			return throw ('error parsing file: ' + unknown);
		}
	}
	
	public static function getStaticFields(x:Class<Dynamic>, filter:EReg = null):Array<{key:String, val:Dynamic}>
	{
		var pairs = new Array();
		
		for (f in Type.getClassFields(x))
		{
			if (f == '__rtti') continue;
			
			if (filter == null)
			{
				pairs.push({key: f, val: Reflect.field(x, f)});
				continue;
			}
			
			if (filter.match(f))
				pairs.push({key: f, val: Reflect.field(x, f)});
		}
		
		return pairs;
	}
}