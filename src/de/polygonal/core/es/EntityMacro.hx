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
import sys.FileSystem;
#end

/**
 * Generates an unique identifier for every class extending de.polygonal.core.es.Entity.
 */
class EntityMacro
{
	macro public static function build():Array<Field>
	{
		//create unique name for local classes defined in a module
		var c = Context.getLocalClass().get();
		
		var className = c.name;
		var moduleName = c.module;
		
		var name = moduleName;
		name = name.substr(name.lastIndexOf(".") + 1); //make unqualified
		if (moduleName.indexOf(className) == -1)
			name += '_$className'; //moduleName_className
		
		next++; //increment unqiue id
		
		var fields = Context.getBuildFields();
		var p = Context.currentPos();
		
		//add "inline public static var ENTITY_TYPE:Int = x"
		fields.push(
		{
			name: "ENTITY_TYPE",
			doc: null,
			meta: [{name: ":keep", pos: p}],
			access: [APublic, AStatic, AInline],
			kind: FVar(TPath({pack: [], name: "Int", params: [], sub: null}), {expr: EConst(CInt(Std.string(next))), pos: p}),
			pos: p
		});
		
		//add "public static var SUPER_CLASS = x"
		var superClass:String = null;
		if (c.superClass != null) superClass = c.superClass.t.get().module;
		if (superClass == null) superClass = "null";
		fields.push(
		{
			name: "SUPER_CLASS",
			doc: null,
			meta: [{name: ":keep", pos: p}],
			access: [APublic, AStatic],
			kind: field(superClass),
			pos: p
		});
		
		//add "public static var ENTITY_NAME:String = x"
		fields.push(
		{
			name: "ENTITY_NAME",
			doc: null,
			meta: [{name: ":keep", pos: p}],
			access: [APublic, AStatic],
			kind: FVar(TPath({pack: [], name: "String", params: [], sub: null}), {expr: EConst(CString('E$name')), pos: p}),
			pos: p
		});
		
		//assign type field in constructor
		var constructorField:Field = null;
		for (field in fields)
		{
			if (field.name == "new")
			{
				constructorField = field;
				break;
			}
		}
		
		if (name == "Entity")
		{
			var fout = sys.io.File.write("./entity_macro.cache", false);
			fout.writeString("" + Date.now());
			fout.close();
			
			Context.registerModuleDependency(c.module, "./entity_macro.cache");
			Context.onMacroContextReused(function()
			{
				next = -1;
				return false;
			});
			
			return fields; //don't modify Entity constructor
		}
		
		//add if (type == 0) type = x;
		var e1 = {expr: EBinop(OpEq, {expr: EConst(CIdent("type")), pos: p}, {expr: EConst(CInt("0")), pos: p}), pos: p};
		var e2 = {expr: EBinop(OpAssign, {expr: EConst(CIdent("type")), pos: p}, {expr: EConst(CInt(Std.string(next))), pos: p}), pos: p};
		var assignType = {expr: EUntyped({expr: EBlock([{expr: EIf(e1, e2, null), pos: p}]), pos: p}), pos: p};
		
		if (constructorField != null)
		{
			switch (constructorField.kind)
			{
				case FFun(f):
					if (f.args.length == 0) //add ?name:String to new()
						f.args.unshift({name: "name", type: TPath({name:"String", pack:[], params:[]}), opt: true});
					
					function checkSuperArgs(i:ExprDef)
					{
						//make sure super() passes name argument to superclass
						switch (i)
						{
							case ECall(a, params):
								switch (a.expr)
								{
									case EConst(b):
										switch (b)
										{
											case CIdent(c):
												if (c == "super")
												{
													if (params.length == 0)
														params.unshift({expr: EConst(CIdent("name")), pos: p});
													else
													{
														var hasName = false;
														for (i in 0...params.length)
														{
															switch (params[i].expr)
															{
																case EConst(d):
																	switch (d)
																	{
																		case CIdent(e):
																			if (e == "name")
																			{
																				hasName = true;
																				if (i > 0) Context.fatalError("name arguments should be in front of additional arguments", p);
																			}
																		case _:
																	}
																case _:
															}
														}
														
														if (!hasName)
															if (superClass != "de.polygonal.core.es.Entity")
																params.unshift({expr: EConst(CIdent("name")), pos: p});
													}
												}
											case _:
										}
									case _:
								}
							case _:
						}
					}
						
					switch (f.expr.expr)
					{
						case ExprDef.EBlock(a):
							for (i in a) checkSuperArgs(i.expr);
							
							//add "type=value" before calling super()
							a.unshift(assignType);
						case _:
					}
				case _:
			}
		}
		else
		{
			constructorField =
			{
				name: "new",
				doc: null,
				meta: [],
				access: [APublic],
				kind: FFun(
				{
					args: [{name: "name", type: TPath({name: "String", pack: [], params: []}), opt: false, value: {expr: EConst(CIdent("null")), pos: p}}],
					ret: null,
					expr: {expr: EBlock([assignType, {expr: ECall({expr: EConst(CIdent("super")), pos: p}, [{expr: EConst(CIdent("name")), pos: p}]), pos: p}]), pos: p},
					params: []
					
				}),
				pos: p
			}
			
			fields.push(constructorField);
		}
		
		return fields;
	}
	
	#if macro
	static var next = -1;
	
	static function field(pkg:String)
	{
		var p = Context.currentPos();
		var a = pkg.split(".");
		var e = {expr: EConst(CIdent(a[0])), pos: p};
		for (i in 1...a.length) e = {expr: EField(e, a[i]), pos: p};
		return FVar(null, e);
	}
	#end
}