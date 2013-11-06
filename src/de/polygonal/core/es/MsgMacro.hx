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
package de.polygonal.core.es;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
#end

class MsgMacro
{
	#if macro
	static var nextId:Int = 0;
	static var names:Array<String> = [];
	static var callbackRegistered:Bool = false;
	#end
	
	macro static function build(e:Expr):Array<Field>
	{
		Context.onMacroContextReused(function()
		{
			nextId = 0;
			names = [];
			return false;
		});
		
		if (!callbackRegistered)
		{
			callbackRegistered = true;
			Context.onGenerate(function(_)
			{
				//add names array meta data to Msg class
				switch (Context.getModule("de.polygonal.core.es.Msg")[0])
				{
					case TInst(t, params):
						var a = [];
						for (name in names)
							a.push({expr: EConst(CString(name)), pos: Context.currentPos()});
						var ct = t.get();	
						if (ct.meta.has("names"))
							ct.meta.remove("names");
						ct.meta.add("names", [{expr: EArrayDecl(a), pos: Context.currentPos()}], Context.currentPos());
					case _:
				}
			});
		}
		
		var pos = Context.currentPos();
		var fields = Context.getBuildFields();
		
		var firstId = nextId;
		
		switch (e.expr)
		{
			case EArrayDecl(a):
				for (b in a)
				{
					switch (b.expr)
					{
						case EConst(c):
							switch (c)
							{
								case CIdent(d):
									names.push(d);
									fields.push(
									{
										name: d,
										doc: null,
										meta: [],
										access: [AStatic, APublic, AInline],
										kind: FVar(TPath({pack: [], name: "Int", params: [], sub: null}), {expr: EConst(CInt(Std.string(nextId))), pos: pos}),
										pos: pos
									});
									nextId++;
								case _: Context.error("unsupported declaration", pos);
							}
						case _: Context.error("unsupported declaration", pos);
					}
				}
			case _: Context.error("unsupported declaration", pos);
		}
		
		/*var cases = new Array<Case>();
		
		for (name in names)
		{
			cases.push(
			{
				values: [{expr: EConst(CInt(Std.string(firstId))), pos: pos}],
				expr: {expr: EBlock([ {expr: EReturn({expr: EConst(CString(name)), pos: pos}), pos: pos} ]), pos: pos}
			});
			
			firstId++;
		}
		
		cases.push(
		{
			values: [{expr: EConst(CIdent("_")), pos: pos}],
			expr: {expr: EBlock([ {expr: EReturn({expr: EConst(CString("unknown")), pos: pos}), pos: pos} ]), pos: pos}
		});
		
		var f =
		{
			args: [{name: "type", opt: false, type: TPath({pack: [], name: "Int", params: [], sub: null}), value: null}],
			ret: TPath({pack: [], name: "String", params: [], sub: null}),
			expr: {expr: EBlock([{expr: ESwitch({expr: EParenthesis({expr: EConst(CIdent('type')), pos: pos}), pos: pos}, cases, null), pos: pos}]), pos: pos},
			params: []
		}
		fields.push({name: "name", doc: null, meta: [], access: [AStatic, APublic], kind: FFun(f), pos: pos});*/
		
		return fields;
	}
}