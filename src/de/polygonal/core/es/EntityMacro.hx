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
package de.polygonal.core.es;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Expr.ExprDef;

import haxe.ds.StringMap;
import haxe.macro.Type;
#end

/**
 * Generates an unique identifier for every class extending de.polygonal.core.es.Entity.
 */
class EntityMacro
{
	#if macro
	inline static var CACHE_PATH = "./entity_id.cache";
	
	static var callbackRegistered = false;
	static var types:StringMap<Int> = null;
	static var cache:String = null;
	static var next = -1;
	static var changed = false;
	
	static var allEntityNames:Array<String>;
	
	macro public static function build():Array<Field>
	{
		if (Context.defined("display")) return null;
		
		//write cache file when done
		if (!callbackRegistered)
		{
			callbackRegistered = true;
			Context.onGenerate(onGenerate);
			Context.registerModuleDependency("de.polygonal.core.es.Entity", CACHE_PATH);
		}
		
		var c = Context.getLocalClass().get();
		/*trace("MODULE ROOT " + c.module + " " + c.name);
		var d = c;
		while (d.superClass != null)
		{
			d = d.superClass.t.get();
			trace("      MODULE " + d.module + " " + d.name);
		}*/
		
		var f = Context.getBuildFields();
		
		//create unique name for local classes
		var name = c.module;
		if (c.module.indexOf(c.name) == -1)
			name += "_" + c.name;
		
		if (cache == null)
			if (sys.FileSystem.exists(CACHE_PATH))
				cache = sys.io.File.getContent(CACHE_PATH);
		
		if (cache != null)
		{
			if (types == null)
			{
				//parse cache file and store in types map
				types = new StringMap<Int>();
				next = -1;
				var ereg = ~/([\w.]+):(\d+)/;
				for (i in cache.split("\n"))
				{
					ereg.match(i);
					var j = Std.parseInt(ereg.matched(2));
					if (j > next) next = j;
					types.set(ereg.matched(1), j);
				}
			}
			
			if (types.exists(name))
			{
				//reuse type
				addType(f, types.get(name), name);
			}
			else
			{
				//append type
				next++;
				addType(f, next, name);
				types.set(name, next);
				cache += "\n" + name + ":" + next;
				changed = true;
			}
		}
		else
		{
			//no cache file exists
			addType(f, 1, name);
			cache = name + ":" + 1;
			changed = true;
		}
		
		return f;
	}
	
	static function addType(fields:Array<Field>, type:Int, name:String)
	{
		//trace("add type " + type + " " + name);
		
		name =
		if (name.indexOf("_") != -1)
		{
			var a = name.split("_");
			a[0].substr(a[0].lastIndexOf(".") + 1) + "_" +
				a[1].substr(a[1].lastIndexOf(".") + 1);
		}
		else
			name.substr(name.lastIndexOf(".") + 1);
		
		//trace('name is $name');
		
		var p = Context.currentPos();
		
		/*if (allEntityNames == null)
		{
			allEntityNames = [];
			allEntityNames.push(name);
		}
		*/
		
		
		//assign name and _type field in constructor
		for (field in fields)
		{
			if (field.name == "new")
			{
				switch (field.kind)
				{
					case FFun(f):
						switch (f.expr.expr)
						{
							case ExprDef.EBlock(a):
								//position of super() expr
								var i = 0;
								/*var hasSuper = false;
								while (i < a.length)
								{
									switch(a[i].expr)
									{
										case ExprDef.ECall(e, p):
											switch (e.expr)
											{
												case EConst(c):
													switch (c)
													{
														case CIdent(s):
															if (s == "super")
															{
																hasSuper = true;
																break;
															}
														case _:
													}
												case _:
											}
										case _:
									}
									i++;
								}*/
								
								if (name == "Entity") return;
								
								a.unshift({expr: EBinop(
									Binop.OpAssign,
									{expr: EField({expr: EConst(CIdent("this")), pos: p}, "_name"), pos: p},
									{expr: EConst(CString(name)), pos: p}
									), pos: p});
								
								//assign name after super()
								/*if (hasSuper)
								{
									var index = name.lastIndexOf(".");
									if (index != -1) name = name.substr(index + 1);
									a.insert(i + 1, assignNameExpr);
								}
								else
								{
									assignNameExpr);
								}*/
								
								/*a.unshift({expr: EBinop(
									Binop.OpAssign,
									{expr: EField({expr: EConst(CIdent("this")), pos: p}, "_type"), pos: p},
									{expr: EConst(CInt(Std.string(type))), pos: p}
									), pos: p});*/
							case _:
						}
					case _:
				}
				break;
			}
		}
		
		//add unique static integer type to every class
		fields.push
		(
			{
				name: "___type",
				doc: null,
				meta: [],
				access: [APublic, AStatic],
				kind: FVar(TPath({pack: [], name: "Int", params: [], sub: null}), {expr: EConst(CInt(Std.string(type))), pos: p}),
				pos: p
			}
		);
	}
	
	static function onGenerate(types:Array<haxe.macro.Type>)
	{
		/*var type = Context.getModule("de.polygonal.core.es.Entity")[0];
		
		switch (type)
		{
			case TInst(a, b):
				
			var x = a.get();
			var statics = x.statics.get();
			trace( "statics : " + statics );
			
			var field:ClassField = 
			{
				name: "allNames",
				doc: null,
				//meta: [],
				//type: TInst(Array,[TInst(String,[])]),
				isPublic: false,
				params: [],
				kind: FVar(AccNormal,AccNormal),
				pos: Context.currentPos(),
			}
			
			//typedef ClassField = {
	//var name : String;
	//var type : Type;
	//var isPublic : Bool;
	//var params : Array<{ name : String, t : Type }>;
	//var meta : MetaAccess;
	//var kind : FieldKind;
	//function expr() : Null<TypedExpr>;
	//var pos : Expr.Position;
	//var doc : Null<String>;
//}
			//statics.push(
			
			trace( "statics : " + statics );
			
			case _:
		}*/
		
		//TInst( t : Ref<ClassType>, params : Array<Type> );
		
		//type.get();
		//type.
		
		
		if (!changed) return;
		var fout = sys.io.File.write(CACHE_PATH, false);
		fout.writeString(cache);
		fout.close();
	}
	#end
}