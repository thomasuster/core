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

import de.polygonal.core.es.Msg;
import de.polygonal.core.util.Assert;
import de.polygonal.core.util.ClassTools;

import de.polygonal.core.es.EntitySystem in ES;

@:access(de.polygonal.core.es.EntitySystem)
@:autoBuild(de.polygonal.core.es.EntityMacro.build())
@:build(de.polygonal.core.es.EntityMacro.build())

@:build(de.polygonal.core.util.IntConstants.build(
[
	BIT_GHOST,
	BIT_SKIP_SUBTREE,
	BIT_SKIP_MSG,
	BIT_SKIP_TICK,
	BIT_SKIP_DRAW,
	BIT_SKIP_UPDATE,
	BIT_STOP_PROPAGATION,
	BIT_MARK_FREE,
	BIT_GLOBAL_NAME,
	BIT_HAS_PROPERTIES
], true, false))
class Entity
{
	inline static function getEntityType<T:Entity>(C:Class<T>):Int
	{
		#if flash
		return untyped C.ENTITY_TYPE;
		#else
		return Reflect.field(C, "ENTITY_TYPE");
		#end
	}
	
	inline static function getMsgQue() return ES.mMsgQue;
	inline static function getInheritanceLookup() return ES.mInheritanceLookup;
	
	/**
	 * A unique identifier for this entity.
	 */
	public var id(default, null):EntityId;
	
	/**
	 * Every subclass of the Entity class can be identified by a unique integer value.
	 */
	public var type(default, never):Int;
	
	/**
	 * A pointer to the next entity in a preorder sequence.
	 */
	public var preorder(default, null):Entity;
	
	@:noCompletion var mFlags:Int;
	@:noCompletion var mName:String;
	
	public function new(?name:String)
	{
		mFlags = 0;
		ES.register(this);
		
		#if debug
		if (name == null)
			name = ClassTools.getUnqualifiedClassName(this);
		#end
		
		if (name != null) mName = name;
	}
	
	/**
	 * Recursively destroys the subtree rooted at this entity (including this entity) from the bottom up.<br/>
	 * The method invokes <em>onFree()</em> on each entity, giving each entity the opportunity to perform some cleanup (e.g. free resources or unregister from listeners).<br/>
	 */
	public function free()
	{
		if (mFlags & BIT_MARK_FREE > 0) return;
		
		var e = this;
		var k = size + 1;
		while (k-- > 0)
		{
			e.mFlags |= BIT_MARK_FREE;
			e = e.preorder;
		}
	}
	
	public var parent(get_parent, set_parent):Entity;
	@:noCompletion inline function get_parent():Entity
	{
		return ES.getParent(this);
	}
	@:noCompletion inline function set_parent(value:Entity)
	{
		ES.setParent(this, value);
		return value;
	}
	
	public var child(get_child, set_child):Entity;
	@:noCompletion inline function get_child():Entity
	{
		return ES.getChild(this);
	}
	@:noCompletion inline function set_child(value:Entity)
	{
		ES.setChild(this, value);
		return value;
	}
	
	public var sibling(get_sibling, set_sibling):Entity;
	@:noCompletion inline function get_sibling():Entity
	{
		return ES.getSibling(this);
	}
	@:noCompletion inline function set_sibling(value:Entity)
	{
		ES.setSibling(this, value);
		return value;
	}
	
	public var lastChild(get_lastChild, set_lastChild):Entity;
	@:noCompletion inline function get_lastChild():Entity
	{
		return ES.getLastChild(this);
	}
	@:noCompletion inline function set_lastChild(value:Entity)
	{
		ES.setLastChild(this, value);
		return value;
	}
	
	/**
	 * The total number of descendants.
	 */
	public var size(get_size, set_size):Int;
	@:noCompletion inline function get_size():Int
	{
		return ES.getSize(this);
	}
	@:noCompletion inline function set_size(value:Int):Int
	{
		ES.setSize(this, value);
		return value;
	}
	
	public var depth(get_depth, set_depth):Int;
	@:noCompletion function get_depth():Int
	{
		return ES.getDepth(this);
	}
	@:noCompletion function set_depth(value:Int):Int
	{
		ES.setDepth(this, value);
		return value;
	}
	
	/**
	 * The total number of children.
	 */
	public var numChildren(get_numChildren, set_numChildren):Int;
	@:noCompletion inline function get_numChildren():Int
	{
		return ES.getNumChildren(this);
	}
	@:noCompletion inline function set_numChildren(value:Int):Int
	{
		ES.setNumChildren(this, value);
		return value;
	}
	
	public var tick(get_tick, set_tick):Bool;
	@:noCompletion inline function get_tick():Bool
	{
		return mFlags & BIT_SKIP_TICK == 0;
	}
	@:noCompletion function set_tick(value:Bool):Bool
	{
		mFlags = value ? (mFlags & ~BIT_SKIP_TICK) : (mFlags | BIT_SKIP_TICK);
		return value;
	}
	
	public var draw(get_draw, set_draw):Bool;
	@:noCompletion inline function get_draw():Bool
	{
		return mFlags & BIT_SKIP_DRAW == 0;
	}
	@:noCompletion function set_draw(value:Bool):Bool
	{
		mFlags = value ? (mFlags & ~BIT_SKIP_DRAW) : (mFlags | BIT_SKIP_DRAW);
		return value;
	}
	
	public var skipUpdate(get_skipUpdate, set_skipUpdate):Bool;
	@:noCompletion inline function get_skipUpdate():Bool
	{
		return mFlags & BIT_SKIP_UPDATE > 0;
	}
	@:noCompletion function set_skipUpdate(value:Bool):Bool
	{
		mFlags = value ? (mFlags | BIT_SKIP_UPDATE) : (mFlags & ~BIT_SKIP_UPDATE);
		return value;
	}
	
	/**
	 * The name of this entity. Default is null.
	 * In case of subclassing, name is set to the unqualified class name of the subclass.
	 */
	public var name(get_name, set_name):String;
	@:noCompletion inline function get_name():String
	{
		return mName;
	}
	@:noCompletion function set_name(value:String):String
	{
		if (value == name) return value;
		if (mFlags & BIT_GLOBAL_NAME > 0)
			ES.changeName(this, value);
		mName = value;
		return value;
	}
	
	public function exposeName()
	{
		if (mFlags & BIT_GLOBAL_NAME == 0)
		{
			mFlags |= BIT_GLOBAL_NAME;
			ES.changeName(this, mName);
		}
	}
	
	public var ghost(get_ghost, set_ghost):Bool;
	@:noCompletion inline function get_ghost():Bool return mFlags & BIT_GHOST > 0;
	@:noCompletion function set_ghost(value:Bool):Bool
	{
		mFlags = value ? (mFlags | BIT_GHOST) : (mFlags & ~BIT_GHOST);
		return value;
	}
	
	public var skipSubtree(get_skipSubtree, set_skipSubtree):Bool;
	@:noCompletion inline function get_skipSubtree():Bool
	{
		return mFlags & BIT_SKIP_SUBTREE > 0;
	}
	@:noCompletion function set_skipSubtree(value:Bool):Bool
	{
		mFlags = value ? (mFlags | BIT_SKIP_SUBTREE) : (mFlags & ~BIT_SKIP_SUBTREE);
		return value;
	}
	
	public var skipMessages(get_skipMessages, set_skipMessages):Bool;
	@:noCompletion inline function get_skipMessages():Bool
	{
		return mFlags & BIT_SKIP_MSG > 0;
	}
	@:noCompletion function set_skipMessages(value:Bool):Bool
	{
		mFlags = value ? (mFlags | BIT_SKIP_MSG) : (mFlags & ~BIT_SKIP_MSG);
		return value;
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
		
		onAddChild(x);
		x.onAdd();
		
		return cast x;
	}
	
	public function remove(x:Entity = null)
	{
		if (x == null || x == this)
		{
			//remove myself
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
	
	public function removeByType<T:Entity>(cl:Class<T>, inheritance = false)
	{
		var child = childByType(cl, inheritance);
		if (child != null) remove(child);
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
	
	public function ancestorByType<T:Entity>(cl:Class<T>, inheritance = false):T
	{
		var e = parent;
		var t = getEntityType(cl);
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
		var t = getEntityType(cl);
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
		var t = getEntityType(cl);
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
		var child = (cl != null ? childByType(cl) : childByName(name));
		return child != null && (child.mFlags & BIT_MARK_FREE == 0);
	}
	
	public function siblingByType<T:Entity>(?cl:Class<T>, inheritance = false):T
	{
		if (parent == null) return null;
		
		var e = parent.child;
		var t = getEntityType(cl);
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
	 * Sends a message to an entity called name.
	 */
	public function msgTo(name:String, msgType:Int, instant = false)
	{
		var e = ES.lookupByName(name);
		if (e == null) return;
		getMsgQue().enqueue(this, e, msgType, 0);
		if (instant) ES.dispatchMessages();
	}
	
	/**
	 * Sends a message to the parent entity.
	 */
	public function msgToParent(msgType:Int, instant = false)
	{
		var e = parent;
		if (e != null) getMsgQue().enqueue(this, e, msgType, 0);
		if (instant) ES.dispatchMessages();
	}
	
	/**
	 * Sends a message to all ancestors.
	 */
	public function msgToAncestors(msgType:Int, instant = false)
	{
		var q = getMsgQue();
		var e = parent;
		if (e == null) return;
		var k = depth;
		while (k-- > 0)
		{
			q.enqueue(this, e, msgType, k);
			e = e.parent;
		}
		if (instant) ES.dispatchMessages();
	}
	
	/**
	 * Sends a message to all descendants.
	 */
	public function msgToDescendants(msgType:Int, instant = false)
	{
		var q = getMsgQue();
		var e = child;
		if (e == null) return;
		var k = size;
		while (k-- > 0)
		{
			q.enqueue(this, e, msgType, k);
			e = e.preorder;
		}
		
		if (instant) ES.dispatchMessages();
	}
	
	/**
	 * Sends a message to all children.
	 */
	public function msgToChildren(msgType:Int, instant = false)
	{
		var q = getMsgQue();
		var e = child;
		if (e == null) return;
		var k = numChildren;
		while (k-- > 0)
		{
			q.enqueue(this, e, msgType, k);
			e = e.sibling;
		}
		
		if (instant) ES.dispatchMessages();
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
		mFlags |= BIT_STOP_PROPAGATION;
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
	inline public function as<T:Entity>(c:Class<T>):T
	{
		#if flash
		return untyped __as__(this, c);
		#else
		return cast this;
		#end
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
	
	inline public function hasProperty(key:String) return ES.hasProperty(this, key);
	
	inline public function getProperty(key:String):Dynamic return ES.getProperty(this, key);
	
	inline public function setProperty(key:String, value:Dynamic) ES.setProperty(this, key, value);
	
	inline public function clrProperty(key:String) ES.clrProperty(this, key);
	
	public function toString():String
	{
		if (name == null) name = '[${ClassTools.getClassName(this)}]';
		return '{ Entity $name }';
	}
	
	@:noCompletion function onAddChild(child:Entity) {}
	
	@:noCompletion function onAdd() {}
	
	@:noCompletion function onRemove(parent:Entity) {}
	
	@:noCompletion function onFree() {}
	
	@:noCompletion function onTick(dt:Float) {}
	
	@:noCompletion function onDraw(alpha:Float) {}
	
	@:noCompletion function onMsg(msgType:Int, sender:Entity) {}
	
	@:noCompletion inline function findPredecessor(e:Entity):Entity
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
	
	@:noCompletion inline function findLastLeaf(e:Entity):Entity
	{
		//find bottom-most, right-most entity in this subtree
		while (e.child != null) e = e.lastChild;
		return e;
	}
	
	@:noCompletion inline function nextSubtree():Entity
	{
		return
		if (sibling != null)
			sibling;
		else
			findLastLeaf(this).preorder;
	}
}