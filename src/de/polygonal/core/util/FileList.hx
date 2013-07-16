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
package de.polygonal.core.util;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import sys.FileSystem;
#end

class FileList
{
	macro public static function build(path:String, flat:Bool = true):Array<Field>
	{
		var reExt = ~/(?<=\.)[a-zA-Z0-9]{3,4}/;
		
		Context.registerModuleDependency(Std.string(Context.getLocalClass()), path);
		
		var pos = Context.currentPos();
		var fields = Context.getBuildFields();
		var all = [];
		
		if (path.lastIndexOf("/") == path.length - 1) path = path.substr(0, path.length - 1);
		
		var files = scan(path);
		for (file in files)
		{
			if (!reExt.match(file)) continue;
			
			var ext = reExt.matched(0);
			
			var fieldName = StringTools.replace(file, "/", "_");
			
			var key = ext + "_" + fieldName.substr(0, fieldName.lastIndexOf("."));
			
			if (flat) file = file.substr(file.lastIndexOf("/") + 1);
			
			var e = {expr: EConst(CString(file)), pos: pos};
			all.push(e);
			
			fields.push
			({
				name: key, doc: null, meta: [], access: [APublic, AStatic, AInline],
				kind: FVar(TPath({pack: [], name: "String", params: [], sub: null}), e), pos: pos
			});
		}
		
		fields.push
		({
			name: "all", doc: null, meta: [], access: [APublic, AStatic], pos: pos,
			kind: FVar(TPath({pack: [], name: "Array", params: [TPType(TPath({sub: null, name: "String", pack: [], params: []}))], sub: null}), {expr: EArrayDecl(all), pos: pos})
		});
		
		fields.push
		({
			name: "path", doc: null, meta: [], access: [APublic, AStatic, AInline], pos: pos,
			kind: FVar(TPath({pack: [], name: "String", params: [], sub: null}), {expr: EConst(CString(path)), pos: pos})
		});
		
		return fields;
	}
	
	#if macro
	static function scan(path:String):Array<String>
	{
		var files = [];
		var stack = [path];
		while (stack.length > 0)
		{
			path = stack.pop();
			if (FileSystem.isDirectory(path))
			{
				for (i in FileSystem.readDirectory(path))
					stack.push('$path/$i');
			}
			else
				files.push(path);
		}
		return files;
	}
	#end
}