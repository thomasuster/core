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
package de.polygonal.core.macro;

import de.polygonal.core.fmt.ASCII;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.rtti.CType.TypeTree;

typedef Pair =
{
	var key:String;
	var val:Dynamic;
}

class PropertyFile
{
	#if macro
	@:macro public static function build(url:String, staticFields:Bool):Array<Field>
	{
		Context.registerModuleDependency(Std.string(Context.getLocalClass()), url);
		var pos = haxe.macro.Context.currentPos();
		
		var fields = Context.getBuildFields();
		var assign = new Array<Expr>();
		
		try
		{
			var s = neko.io.File.getContent(url);
			
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
			
			if (b != '')
				a.push(b);
			
			var access = [APublic];
			if (staticFields)
			{
				access.push(AStatic);
				access.push(AInline);
			}
			
			var next = 0;
			for (i in 0...a.length >> 1)
			{
				var fieldName  = a[next++];
				var fieldValue = a[next++];
				
				var c = null, n:String, p = [];
				if (fieldValue.indexOf(',') != -1)
				{
					var arrExpr = [];
					var arrType;
					var tmp = fieldValue.split(',');
					
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
				if (fieldValue.indexOf('.') != -1)
				{
					if (Math.isNaN(Std.parseFloat(fieldValue)))
					{
						c = EConst(CString(fieldValue));
						n = 'String';
					}
					else
					{
						c = EConst(CFloat(fieldValue));
						n = 'Float';
					}
				}
				else
				if (fieldValue == 'true' || fieldValue == 'false')
				{
					c = EConst(CIdent(fieldValue));
					n = 'Bool';
				}
				else
				{
					var int = Std.parseInt(fieldValue);
					if (int == null)
					{
						c = EConst(CString(fieldValue));
						n = 'String';
					}
					else
					{
						c = EConst(CInt(fieldValue));
						n = 'Int';
					}
				}
				
				if (c == null)
					Context.error('invalid field type', Context.currentPos());
				
				if (staticFields)
					fields.push({name: fieldName, doc: null, meta: [], access: access, kind: FVar(TPath({pack: [], name: n, params: p, sub: null}), {expr: c, pos: pos}), pos: pos});
				else
				{
					fields.push({name: fieldName, doc: null, meta: [], access: access, kind: FVar(TPath({pack: [], name: n, params: p, sub: null})), pos: pos});
					assign.push({expr: EBinop(Binop.OpAssign, {expr: EConst(CIdent(fieldName)), pos: pos}, {expr: c, pos: pos}), pos:pos});
				}
			}
		}
		catch (unknown:Dynamic)
		{
			Context.error('error parsing file: ' + unknown, Context.currentPos());
		}
		
		if (!staticFields) fields.push({name: 'new', doc: null, meta: [], access: [APublic], kind: FFun({args: [], ret: null, expr: {expr: EBlock(assign), pos:pos}, params: []}), pos: pos});
		return fields;
	}
	#end
	
	public static function getStaticFields(x:Class<Dynamic>, filter:EReg = null):Array<Pair>
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