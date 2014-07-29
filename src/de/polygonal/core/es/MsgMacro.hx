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
package de.polygonal.core.es;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
#end

class MsgMacro
{
	#if macro
	static var mNextId:Int = 0;
	static var mNames:Array<String> = [];
	#end
	
	macro static function build(e:Expr):Array<Field>
	{
		var pos = Context.currentPos();
		var fields = Context.getBuildFields();
		
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
									mNames.push(d);
									fields.push(
									{
										name: d,
										doc: null,
										meta: [],
										access: [AStatic, APublic, AInline],
										kind: FVar(TPath({pack: [], name: "Int", params: [], sub: null}), {expr: EConst(CInt(Std.string(mNextId))), pos: pos}),
										pos: pos
									});
									mNextId++;
									
									if (mNextId > 0x7FFF) Context.error("message type out of range [0, 0x7FFF]", pos);
									
								case _: Context.error("unsupported declaration", pos);
							}
						case _: Context.error("unsupported declaration", pos);
					}
				}
			case _: Context.error("unsupported declaration", pos);
		}
		
		return fields;
	}
	
	macro static function addMeta():Array<Field>
	{
		var pos = Context.currentPos();
		
		Context.onGenerate(function(_)
		{
			switch (Context.getModule("de.polygonal.core.es.Msg")[0])
			{
				case TInst(t, params):
					var a = [];
					for (name in mNames)
						a.push({expr: EConst(CString(name)), pos: pos});
					var ct = t.get();
					if (ct.meta.has("names"))
					{
						ct.meta.remove("names");
						ct.meta.remove("count");
					}
					ct.meta.add("names", [{expr: EArrayDecl(a), pos: pos}], pos);
					ct.meta.add("count", [{expr: EConst(CString(Std.string(mNextId))), pos: pos}], pos);
				case _:
			}
		});
		
		return Context.getBuildFields();
	}
}