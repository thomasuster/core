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

import de.polygonal.core.es.Msg;
import de.polygonal.core.util.Assert;

import de.polygonal.core.es.EntitySystem in ES;

@:access(de.polygonal.core.es.EntitySystem)
@:autoBuild(de.polygonal.core.es.EntityMacro.build())
@:build(de.polygonal.core.es.EntityMacro.build())
class Entity
{
	inline static var BIT_GHOST            = 0x10000; //lower 16 bits are reserved for class type
	inline static var BIT_SKIP_SUBTREE     = 0x20000;
	inline static var BIT_SKIP_MSG         = 0x40000;
	inline static var BIT_SKIP_TICK        = 0x80000;
	inline static var BIT_SKIP_DRAW        = 0x100000;
	inline static var BIT_STOP_PROPAGATION = 0x200000;
	
	inline static function getClassType<T>(C:Class<T>):Int
	{
		#if flash
		return untyped C.___type;
		#else
		return Reflect.field(C, "___type");
		#end
	}
	
	inline static function getMsgQue() return ES._msgQue;
	inline static function getInheritanceLookup() return ES._inheritanceLookup;
	
	/**
	 * Every entity can be identified by a unique id.
	 */
	public var id(default, null):EntityId;
	
	public var preorder(default, null):Entity;
	
	var _flags:Int;
	var _name:String;
	
	public function new(name:String = null)
	{
		if (name != null) _name = name;
		
		D.assert(ES._initialized, "call EntitySystem.init() first");
		ES.add(this);
	}
	
	public function commit()
	{
		L.e('called commit');
	}
	
	/**
	 * Recursively destroys the subtree rooted at this entity (including this entity) from the bottom up.<br/>
	 * The method invokes <em>onFree()</em> on each entity, giving each entity the opportunity to perform some cleanup (e.g. free resources or unregister from listeners).<br/>
	 */
	public function free()
	{
		if (freed) return;
		
		//unlink
		if (parent != null) remove(this);
		
		//bottom-up deconstruction
		ES.freeEntity(this);
	}
	
	/**
	 * Every subclass of the Entity class is defined by a unique integer value.
	 */
	public var type(get_type, never):Int;
	inline function get_type():Int
	{
		return _flags & 0xffff;
	}
	
	public var parent(get_parent, set_parent):Entity;
	inline function get_parent():Entity
	{
		return ES.getParent(this);
	}
	inline function set_parent(value:Entity)
	{
		ES.setParent(this, value);
		return value;
	}
	
	public var child(get_child, set_child):Entity;
	inline function get_child():Entity
	{
		return ES.getChild(this);
	}
	inline function set_child(value:Entity)
	{
		ES.setChild(this, value);
		return value;
	}
	
	public var sibling(get_sibling, set_sibling):Entity;
	inline function get_sibling():Entity
	{
		return ES.getSibling(this);
	}
	inline function set_sibling(value:Entity)
	{
		ES.setSibling(this, value);
		return value;
	}
	
	public var lastChild(get_lastChild, set_lastChild):Entity;
	inline function get_lastChild():Entity
	{
		return ES.getLastChild(this);
	}
	inline function set_lastChild(value:Entity)
	{
		ES.setLastChild(this, value);
		return value;
	}
	
	public var size(get_size, set_size):Int;
	inline function get_size():Int
	{
		return ES.getSize(this);
	}
	inline function set_size(value:Int):Int
	{
		ES.setSize(this, value);
		return value;
	}
	
	public var depth(get_depth, set_depth):Int;
	function get_depth():Int
	{
		return ES.getDepth(this);
	}
	function set_depth(value:Int):Int
	{
		ES.setDepth(this, value);
		return value;
	}
	
	public var numChildren(get_numChildren, set_numChildren):Int;
	inline function get_numChildren():Int
	{
		return ES.getNumChildren(this);
	}
	inline function set_numChildren(value:Int):Int
	{
		ES.setNumChildren(this, value);
		return value;
	}
	
	public var freed(get_freed, never):Bool;
	inline function get_freed():Bool
	{
		return id == null || id.index == -1;
	}
	
	public var tick(get_tick, set_tick):Bool;
	inline function get_tick():Bool
	{
		return getFlags() & BIT_SKIP_TICK == 0;
	}
	function set_tick(value:Bool):Bool
	{
		setFlags(value ? (getFlags() & ~BIT_SKIP_TICK) : (getFlags() | BIT_SKIP_TICK));
		return value;
	}
	
	public var draw(get_draw, set_draw):Bool;
	inline function get_draw():Bool
	{
		return getFlags() & BIT_SKIP_DRAW == 0;
	}
	function set_draw(value:Bool):Bool
	{
		setFlags(value ? (getFlags() & ~BIT_SKIP_DRAW) : (getFlags() | BIT_SKIP_DRAW));
		return value;
	}
	
	/**
	 * The name of this entity. Default is null.
	 * In case of subclassing, name is set to the unqualified class name of the subclass.
	 */
	public var name(get_name, set_name):String;
	inline function get_name():String
	{
		return _name;
	}
	function set_name(value:String):String
	{
		ES.changeName(this, value);
		return value;
	}
	
	public var ghost(get_ghost, set_ghost):Bool;
	function get_ghost():Bool return getFlags() & BIT_GHOST > 0;
	function set_ghost(value:Bool):Bool
	{
		setFlags(value ? (getFlags() | BIT_GHOST) : (getFlags() & ~BIT_GHOST));
		return value;
	}
	
	public var skipSubtree(get_skipSubtree, set_skipSubtree):Bool;
	function get_skipSubtree():Bool
	{
		return getFlags() & BIT_SKIP_SUBTREE > 0;
	}
	function set_skipSubtree(value:Bool):Bool
	{
		setFlags(value ? (getFlags() | BIT_SKIP_SUBTREE) : (getFlags() & ~BIT_SKIP_SUBTREE));
		return value;
	}
	
	public var skipMessages(get_skipMessages, set_skipMessages):Bool;
	function get_skipMessages():Bool
	{
		return getFlags() & BIT_SKIP_MSG > 0;
	}
	function set_skipMessages(value:Bool):Bool
	{
		setFlags(value ? (getFlags() | BIT_SKIP_MSG) : (getFlags() & ~BIT_SKIP_MSG));
		return value;
	}
	
	public function propagateTick(dt:Float)
	{
		var e = child;
		while (e != null)
		{
			if ((e.getFlags()) & (BIT_GHOST | BIT_SKIP_TICK) == 0)
				e.onTick(dt);
			
			if ((e.getFlags()) & BIT_SKIP_SUBTREE > 0)
			{
				e =
				if (e.sibling != null)
					e.sibling;
				else
					findLastLeaf(e).preorder;
				continue;
			}
				
			e = e.preorder;
		}
	}
	
	public function propagateDraw(alpha:Float)
	{
		var e = child;
		while (e != null)
		{
			if ((e.getFlags()) & (BIT_GHOST | BIT_SKIP_DRAW) == 0)
				e.onDraw(alpha);
				
			if ((e.getFlags()) & BIT_SKIP_SUBTREE > 0)
			{
				e =
				if (e.sibling != null)
					e.sibling;
				else
					findLastLeaf(e).preorder;
				continue;
			}
			
			e = e.preorder;
		}
	}
	
	public function add<T:Entity>(?cl:Class<T>, ?inst:T):T
	{
		var x:Entity = inst;
		if (x == null)
			x = Type.createInstance(cl, []);
		
		D.assert(x.parent != this);
		D.assert(x.parent == null);
		
		x.parent = this;
		
		//update #children
		numChildren++;
		
		//update size on ancestors
		var k = x.size + 1;
		size += k;
		var p = parent;
		while (p != null)
		{
			p.size += k;
			p = p.parent;
		}
		
		if (child == null)
		{
			//case 1: without children
			child = x;
			x.sibling = null;
			
			//fix preorder pointer
			var i = findLastLeaf(x);
			i.preorder = preorder;
			preorder = x;
		}
		else
		{
			//case 2: with children
			//fix preorder pointers
			var i = findLastLeaf(lastChild);
			var j = findLastLeaf(x);
			
			j.preorder = i.preorder;
			i.preorder = x;
			
			lastChild.sibling = x;
		}
		
		//update depth on subtree
		var d = depth + 1;
		var e = x;
		var i = x.size + 1;
		while (i-- > 0)
		{
			e.depth += d;
			e = e.preorder;
		}
		
		lastChild = x;
		
		x.onAdd();
		
		return cast x;
	}
	
	public function remove(x:Entity = null)
	{
		if (x == null || x == this)
		{
			D.assert(parent != null);
			parent.remove(this);
			return;
		}
		
		D.assert(x.parent != null);
		D.assert(x != this);
		D.assert(x.parent == this);
		
		//update #children
		numChildren--;
		
		//update size on ancestors
		var k = x.size + 1;
		size -= k;
		var p = parent;
		while (p != null)
		{
			p.size -= k;
			p = p.parent;
		}
		
		//case 1: first child is removed
		if (child == x)
		{
			//update lastChild
			if (child.sibling == null)
				lastChild = null;
			
			var i = findLastLeaf(x);
			
			preorder = i.preorder;
			i.preorder = null;
			
			child = x.sibling;
			x.sibling = null;
		}
		else
		{
			//case 2: second to last child is removed
			var prev = child.findPredecessor(x);
			
			D.assert(prev != null);
			
			//update lastChild
			if (x.sibling == null)
				lastChild = prev;
			
			var i = findLastLeaf(prev);
			var j = findLastLeaf(x);
			
			i.preorder = j.preorder;
			j.preorder = null;
			
			prev.sibling = x.sibling;
			x.sibling = null;
		}
		
		//update depth on subtree
		var d = depth + 1;
		var e = x;
		var i = x.size + 1;
		while (i-- > 0)
		{
			e.depth -= d;
			e = e.preorder;
		}
		
		x.parent = null;
		x.onRemove(this);
	}
	
	public function removeAllChildren()
	{
		var e = child;
		while (e != null)
		{
			var next = e.sibling;
			
			var i = findLastLeaf(e);
			preorder = i.preorder;
			i.preorder = null;
			
			e.parent = e.sibling = null;
			e = next;
		}
		
		child = null;
		lastChild = null;
	}
	
	public function revealSiblings()
	{
		var i = child, j;
		while (i != null)
		{
			j = i.sibling;
			while (j != null)
			{
				i.onSibling(j);
				j.onSibling(i);
				j = j.sibling;
			}
			i = i.sibling;
		}
	}
	
	public function revealAncestors()
	{
		var e = parent;
		while (e != null)
		{
			onAncestor(e);
			e = e.parent;
		}
	}
	
	public function revealDescendants()
	{
		var e = child;
		var k = size;
		while (k-- > 0)
		{
			onDescedant(e);
			e = e.preorder;
		}
	}
	
	public function ancestorByType<T:Entity>(cl:Class<T>, inheritance = false):T
	{
		var e = parent;
		var t = getClassType(cl);
		if (inheritance)
		{
			var lut = getInheritanceLookup();
			while (e != null)
			{
				if (lut.hasPair(e.type, t)) break;
				e = e.parent;
			}
		}
		else
		{
			while (e != null)
			{
				if (e.type == t) break;
				e = e.parent;
			}
		}
		return cast e;
	}
	
	public function ancestorByName(name:String):Entity
	{
		var e = parent;
		while (e != null)
		{
			if (e.name == name) break;
			e = e.parent;
		}
		
		return e;
	}
	
	public function descendantByType<T:Entity>(cl:Class<T>, inheritance = false):T
	{
		var last =
		if (sibling != null)
			sibling;
		else
			findLastLeaf(this).preorder;
		var e = child;
		var t = getClassType(cl);
		if (inheritance)
		{
			var lut = getInheritanceLookup();
			while (e != last)
			{
				if (lut.hasPair(e.type, t)) break;
				e = e.preorder;
			}
		}
		else
		{
			while (e != last)
			{
				if (t == e.type) break;
				e = e.preorder;
			}
		}
		
		return cast e;
	}
	
	public function descendantByName(name:String):Entity
	{
		var e = child;
		var last = sibling;
		while (e != last)
		{
			if (e.name == name) break;
			e = e.preorder;
		}
		
		return e;
	}
	
	public function childByType<T:Entity>(cl:Class<T>, inheritance = false):T
	{
		var e = child;
		var t = getClassType(cl);
		if (inheritance)
		{
			var lut = getInheritanceLookup();
			while (e != null)
			{
				if (lut.hasPair(e.type, t)) break;
				e = e.sibling;
			}
		}
		else
		{
			while (e != null)
			{
				if (t == e.type) break;
				e = e.sibling;
			}
		}
		
		return cast e;
	}
	
	public function childByName(name:String):Entity
	{
		var e = child;
		while (e != null)
		{
			if (e.name == name) break;
			e = e.sibling;
		}
		
		return e;
	}
	
	public function childExists(cl:Class<Dynamic> = null, name:String = null):Bool
	{
		return (cl != null ? childByType(cl) : childByName(name)) != null;
	}
	
	public function siblingByType<T:Entity>(?cl:Class<T>, inheritance = false):T
	{
		if (parent == null) return null;
		
		var e = parent.child;
		var t = getClassType(cl);
		if (inheritance)
		{
			var lut = getInheritanceLookup();
			while (e != null)
			{
				if (e != this)
					if (lut.hasPair(e.type, t))
						break;
				e = e.sibling;
			}
		}
		else
		{
			while (e != null)
			{
				if (e != this)
					if (t == e.type)
						break;
				e = e.sibling;
			}
		}
		
		return cast e;
	}
	
	public function siblingByName(name:String):Entity
	{
		if (parent == null) return null;
		
		var e = parent.child;
		while (e != null)
		{
			if (e.name == name)
				return e;
			e = e.sibling;
		}
		
		return e;
	}

	inline public function putMsgData(o:Dynamic):Entity
	{
		getMsgQue().putData(o);
		return this;
	}
	
	inline public function getMsgData():Dynamic
	{
		return getMsgQue().getData();
	}
	
	/**
	 * Sends a message to all entities of a given name.
	 */
	public function msgTo(name:String, msgType:Int)
	{
		var e = ES.lookupByName(name);
		if (e == null) return;
		
		var q = getMsgQue();
		var k = e.length;
		while (k-- > 0)
			q.enqueue(this, e[k], msgType, k);
	}
	
	/**
	 * Sends a message to all ancestors.
	 */
	public function msgToAncestors(msgType:Int)
	{
		var q = getMsgQue();
		var e = parent;
		var k = depth;
		while (k-- > 0)
		{
			q.enqueue(this, e, msgType, k);
			e = e.parent;
		}
	}
	
	/**
	 * Sends a message to all descendants.
	 */
	public function msgToDescendants(msgType:Int)
	{
		var q = getMsgQue();
		var e = child;
		var k = size;
		while (k-- > 0)
		{
			q.enqueue(this, e, msgType, k);
			e = e.preorder;
		}
	}
	
	/**
	 * Sends a message to all children.
	 */
	public function msgToChildren(msgType:Int)
	{
		var q = getMsgQue();
		var e = child;
		var k = numChildren;
		while (k-- > 0)
		{
			q.enqueue(this, e, msgType, k);
			e = e.sibling;
		}
	}
	
	/**
	 * Sends a message to all siblings.
	 */
	public function msgToSiblings(msgType:Int)
	{
		if (parent != null) parent.msgToChildren(msgType);
	}
	
	/**
	 * Returns the root entity.
	 */
	public function getRoot():Entity
	{
		var e = parent;
		if (e == null) return this;
		while (e.parent != null) e = e.parent;
		return e;
	}
	
	public function getChildIndex():Int
	{
		var p = parent;
		if (p == null) return -1;
		
		var i = 0;
		var e = p.child;
		while (e != this)
		{
			i++;
			e = e.sibling;
		}
		return i;
	}
	
	public function getChildAt(index:Int):Entity
	{
		D.assert(index >= 0 && index < numChildren, 'index $index out of range');
		
		var i = 0;
		var e = child;
		for (i in 0...index)
			e = e.sibling;
		return e;
	}
	
	/**
	 * Successively swaps this entity with its next siblings until it becomes the last sibling.
	 */
	public function setLast():Void
	{
		if (parent == null || sibling == null) return; //no parent or already last?
		
		var c = parent.child;
		if (c == this) //first child?
		{
			while (c.sibling != null) c = c.sibling; //find last child
			c.sibling = this;
			
			preorder = c.preorder;
			c.preorder = this;
			parent.child = parent.preorder = sibling;
		}
		else
		{
			while (c != null) //find predecessor to this
			{
				if (c.sibling == this) break;
				c = c.sibling;
			}
			
			c.sibling = c.preorder = sibling;
			sibling.sibling = this;
			preorder = sibling.preorder;
			sibling.preorder = this;
		}
		
		sibling = null;
		parent.lastChild = this;
	}
	
	/**
	 * Successively swaps this entity with its previous siblings until it becomes the first sibling.
	 */
	public function setFirst():Void
	{
		if (parent == null) return; //no parent?
		if (parent.child == this) return; //first child?
		
		var c = parent.child;
		var pre = c.findPredecessor(this);
		
		if (sibling == null)
			parent.lastChild = this;
		
		pre.preorder = preorder;
		pre.sibling = sibling;
		preorder = sibling = c;
		parent.child = parent.preorder = this;
	}
	
	/**
	 * Returns true if <code>e</code> is a descendant of this entity.
	 */
	public function hasDescendant(e:Entity):Bool
	{
		var i = child;
		var k = size;
		while (k-- > 0)
		{
			if (i == e) return true;
			i = i.preorder;
		}
		return false;
	}
	
	/**
	 * Returns true if <code>e</code> is a child of this entity.
	 */
	public function hasChild(e:Entity):Bool
	{
		var i = child;
		while (i != null)
		{
			if (i == e) return true;
			i = i.sibling;
		}
		return false;
	}
	
	/**
	 * Stops message propagation if called inside <code>onMsg()</code>.
	 */
	inline public function stop()
	{
		setFlags(BIT_STOP_PROPAGATION);
	}
	
	/**
	 * Returns true if this entity has children.
	 */
	inline public function hasChildren():Bool
	{
		return child != null;
	}
	
	/**
	 * Convenience method for casting this Entity to the type <code>cl</code>.
	 */
	inline public function as<T:Entity>(cl:Class<T>):T
	{
		return cast this;
	}
	
	/**
	 * Convenience method for Std.is(this, <code>x</code>);
	 */
	inline public function is<T>(cl:Class<T>):Bool
	{
		#if flash
		return untyped __is__(this, cl);
		#else
		return Std.is(this, cl);
		#end
	}
	
	/**
	 * Handles multiple calls to <em>is()</em> in one shot by checking all classes in <code>x</code> against this class.
	 */
	public function isAny(cl:Array<Class<Dynamic>>):Bool
	{
		for (i in cl)
			if (is(cast i))
				return true;
		return false;
	}
	
	public function toString():String
	{
		if (name == null) return "{ Entity }";
		return '{ Entity $name }';
	}
	
	function onAdd()
	{
	}
	
	function onSibling(sibling:Entity)
	{
	}
	
	function onAncestor(ancestor:Entity)
	{
	}
	
	function onDescedant(descendant:Entity)
	{
	}
	
	function onRemove(parent:Entity)
	{
	}
	
	function onFree()
	{
	}
	
	function onTick(dt:Float)
	{
	}
	
	function onDraw(alpha:Float)
	{
	}
	
	function onMsg(msgType:Int, sender:Entity)
	{
	}
	
	inline function findPredecessor(e:Entity):Entity
	{
		D.assert(parent == e.parent);
		 
		var i = this;
		while (i != null)
		{
			if (i.sibling == e) break;
			i = i.sibling;
		}
		return i;
	}
	
	inline function findLastLeaf(e:Entity):Entity
	{
		//find bottom-most, right-most entity in this subtree
		while (e.child != null) e = e.lastChild;
		return e;
	}
	
	inline function getFlags() return _flags & 0xffff0000;
	
	inline function setFlags(x:Int) _flags |= x;
	
	inline function clrFlags(x:Int) _flags &= ~x;
}