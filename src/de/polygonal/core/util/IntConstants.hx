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
package de.polygonal.core.util;

import haxe.ds.StringMap;
import haxe.macro.Context;
import haxe.macro.Expr;

class IntConstants
{
	#if macro
	static var mNext:StringMap<Int>;
	#end
	
	macro public static function build(e:Expr, bitFlags:Bool, publicAccess:Bool, group:String = null):Array<Field>
	{
		var pos = Context.currentPos();
		var fields = Context.getBuildFields();
		
		var index = 0;
		var count = 0;
		
		if (mNext == null)
			mNext = new StringMap<Int>();
		if (group != null)
			if (!mNext.exists(group)) mNext.set(group, 0);
		
		function next()
		{
			count++;
			if (group == null)
				return index++;
			else
			{
				var i = mNext.get(group);
				mNext.set(group, i + 1);
				return i;
			}
		}
		
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
									var i = next();
									var val = bitFlags ? (1 << i) : i;
									fields.push
									({
										name: d,
										doc: null,
										meta: [],
										access: [AStatic, publicAccess ? APublic : APrivate, AInline],
										kind: FVar(TPath( { pack: [], name: "Int", params: [], sub: null } ), { expr: EConst(CInt(Std.string(val))), pos: pos } ),
										pos: pos
									});
								default: Context.error("unsupported declaration", pos);
							}
						default: Context.error("unsupported declaration", pos);
					}
				}
			default: Context.error("unsupported declaration", pos);
		}
		
		fields.push
		({
			name: "NUM_FIELDS", doc: null, meta: [], access: [APublic, AStatic, AInline], pos: pos,
			kind: FVar(TPath( { pack: [], name: "Int", params: [], sub: null } ), { expr: EConst(CInt(Std.string(count))), pos: pos } ),
		});
		
		return fields;
	}
}