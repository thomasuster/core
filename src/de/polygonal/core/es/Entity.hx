package de.polygonal.core.es;

import de.polygonal.core.util.Assert;
import de.polygonal.core.util.ClassUtil;
import de.polygonal.ds.IntHashSet;
import haxe.ds.StringMap;
import haxe.ds.Vector;

@:access(de.polygonal.core.es.EntityManager)
@:build(de.polygonal.core.es.EntityMacro.build())
@:autoBuild(de.polygonal.core.es.EntityMacro.build())
class Entity
{
	inline static var BIT_GHOST            = 0x10;
	inline static var BIT_SKIP_SUBTREE     = 0x20;
	inline static var BIT_SKIP_MSG         = 0x40;
	inline static var BIT_SKIP_TICK        = 0x80;
	inline static var BIT_SKIP_DRAW        = 0x100;
	inline static var BIT_STOP_PROPAGATION = 0x200;
	
	inline static function getClassType<T>(C:Class<T>):Int
	{
		#if flash
		return untyped C.___type;
		#else
		return Reflect.field(C, "___type");
		#end
	}
	
	public var id(default, null):EntityId;
	
	public var preorder(default, null):Entity;
	
	public var parent(default, null):Entity;
	public var child(default, null):Entity;
	public var sibling(default, null):Entity;
	public var lastChild(default, null):Entity;
	
	public var size(default, null):Int;
	public var numChildren(default, null):Int;
	public var depth(default, null):Int;
	
	var _name:String;
	
	//TODO combine into single integer or store in EntityManager
	var _bits:Int; //8 bits
	var _type:Int; //8 bits , check < 0x100 , otherwise throw error
	
	//var _size:Int; //16 bits sufficient 16xxx
	//var _numChildren:Int;
	//var _depth:Int;
	
	public function new(name:String = null)
	{
		_name = name;
		
		//TODO optimize
		var c = Type.getClass(this);
		_type = getClassType(c);
		
		EntityManager.add(this);
	}
	
	/*inline function getType():Int
	{
		return (_data >> 8) & 0xff;
	}*/
	
	/*inline function getSize():Int
	{
		return (_data >> 16) & 0xff;
	}*/
	
	public function free()
	{
		if (freed) return;
		
		//unlink
		if (parent != null) remove(this);
		
		//free subtree
		var e = child;
		while (e != null)
		{
			var next = e.preorder;
			e.parent = e.child = e.sibling = e.preorder = null;
			EntityManager.remove(e);
			#if verbose
			L.d('free $e', "entity");
			#end
			e.onFree();
			e = next;
		}
		
		//free this
		parent = child = sibling = preorder = null;
		EntityManager.remove(this);
		#if verbose
		L.d('free $e', "entity");
		#end
		onFree();
	}
	
	//0: entity
	/*inline static var TYPE_PARENT   = 0;
	inline static var TYPE_CHILD    = 1;
	inline static var TYPE_SIBLING  = 2;
	inline static var TYPE_LAST_CHILD = 3;
	
	inline function getTopology(type:Int)
	{
		return EntityManager._freeList[EntityManager._topology[(id.index << 3) + type]];
		
		//return EntityManager._freeList[(id.index << 2) + type];
	}
	
	inline function setTopology(type:Int, value:Entity)
	{
		EntityManager._topology[(id.index << 3) + type] = value == null ? 0 : value.id.index;
		
		//EntityManager._freeList[(id.index << 2) + type] = value;
	}*/
	
	/*public var size(get_size, set_size):Int;
	inline function get_size():Int
	{
		return _size;
	}
	inline function set_size(value:Int):Int
	{
		_size = value;
		return value;
	}
	
	public var depth(get_depth, set_depth):Int;
	function get_depth():Int
	{
		return _depth;
	}
	function set_depth(value:Int):Int
	{
		_depth = value;
		return value;
	}
	
	public var numChildren(get_numChildren, set_numChildren):Int;
	inline function get_numChildren():Int
	{
		return _numChildren;
	}
	inline function set_numChildren(value:Int):Int
	{
		_numChildren = value;
		return value;
	}*/
	
	/*public var parent(get_parent, set_parent):Entity;
	inline function get_parent():Entity return getTopology(TYPE_PARENT);
	inline function set_parent(value:Entity)
	{
		setTopology(TYPE_PARENT, value);
		return value;
	}
	
	public var child(get_child, set_child):Entity;
	inline function get_child():Entity return getTopology(TYPE_CHILD);
	inline function set_child(value:Entity)
	{
		setTopology(TYPE_CHILD, value);
		return value;
	}
	
	public var sibling(get_sibling, set_sibling):Entity;
	inline function get_sibling():Entity return getTopology(TYPE_SIBLING);
	inline function set_sibling(value:Entity)
	{
		setTopology(TYPE_SIBLING, value);
		return value;
	}*/
	
	public var freed(get_freed, never):Bool;
	inline function get_freed():Bool return id == null || id.index == -1;
	
	public var tick(get_tick, set_tick):Bool;
	inline function get_tick():Bool return _bits & BIT_SKIP_TICK == 0;
	function set_tick(value:Bool):Bool
	{
		_bits = value ? (_bits & ~BIT_SKIP_TICK) : (_bits | BIT_SKIP_TICK);
		return value;
	}
	
	public var draw(get_draw, set_draw):Bool;
	inline function get_draw():Bool return _bits & BIT_SKIP_DRAW == 0;
	function set_draw(value:Bool):Bool
	{
		_bits = value ? (_bits & ~BIT_SKIP_DRAW) : (_bits | BIT_SKIP_DRAW);
		return value;
	}
	
	public var name(get_name, set_name):String;
	inline function get_name():String return _name;
	function set_name(value:String):String
	{
		EntityManager.changeName(this, value);
		return value;
	}
	
	public var ghost(get_ghost, set_ghost):Bool;
	function get_ghost():Bool return _bits & BIT_GHOST > 0;
	function set_ghost(value:Bool):Bool
	{
		//if (value != get_ghost()) invalidate();
		_bits = value ? (_bits | BIT_GHOST) : (_bits & ~BIT_GHOST);
		return value;
	}
	
	public var skipSubtree(get_skipSubtree, set_skipSubtree):Bool;
	function get_skipSubtree():Bool return _bits & BIT_SKIP_SUBTREE > 0;
	function set_skipSubtree(value:Bool):Bool
	{
		//if (value != get_skipSubtree()) invalidate();
		_bits = value ? (_bits | BIT_SKIP_SUBTREE) : (_bits & ~BIT_SKIP_SUBTREE);
		return value;
	}
	
	public var skipMessages(get_skipMessages, set_skipMessages):Bool;
	function get_skipMessages():Bool return _bits & BIT_SKIP_MSG > 0;
	function set_skipMessages(value:Bool):Bool
	{
		_bits = value ? (_bits | BIT_SKIP_MSG) : (_bits & ~BIT_SKIP_MSG);
		return value;
	}
	
	public function propagateTick(dt:Float)
	{
		var e = child;
		while (e != null)
		{
			if (e._bits & (BIT_GHOST | BIT_SKIP_TICK) == 0)
				e.onTick(dt);
			
			if (e._bits & BIT_SKIP_SUBTREE > 0)
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
			if (e._bits & (BIT_GHOST | BIT_SKIP_DRAW) == 0)
				e.onDraw(alpha);
				
			if (e._bits & BIT_SKIP_SUBTREE > 0)
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
		
		var isLast = x.sibling == null;
		
		//case 1: first child is removed
		if (child == x)
		{
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
		
		if (isLast) lastChild = null;
		
		x.onRemove();
		x.parent = null;
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
	
	public function ancestorByType<T:Entity>(?cl:Class<T>, inheritanceChain = false):T
	{
		var type = getClassType(cl);
		var e = child;
		
		if (inheritanceChain)
		{
			var t = EntityManager._types;
			while (e != null)
			{
				if (t.has(e._type << 16 | type)) break;
				e = e.parent;
			}
		}
		else
		{
			while (e != null)
			{
				if (e._type == type) break;
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
	
	public function descendantByType<T:Entity>(?cl:Class<T>, inheritanceChain = false):T
	{
		var type = getClassType(cl);
		var e = child;
		var last = sibling;
		
		if (inheritanceChain)
		{
			var types = EntityManager._types;
			while (e != last)
			{
				if (types.has(e._type << 16 | type)) break;
				e = e.preorder;
			}
		}
		else
		{
			while (e != last)
			{
				if (type == e._type) break;
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
	
	public function childByType<T:Entity>(?cl:Class<T>, inheritanceChain = false):T
	{
		var type = getClassType(cl);
		var e = child;
		
		if (inheritanceChain)
		{
			var types = EntityManager._types;
			while (e != null)
			{
				if (types.has(e._type << 16 | type))
					break;
				e = e.sibling;
			}
		}
		else
		{
			while (e != null)
			{
				if (type == e._type) break;
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
	
	public function siblingByType<T:Entity>(?cl:Class<T>, inheritanceChain = false):T
	{
		if (parent == null) return null;
		
		var e = parent.child;
		var type = getClassType(cl);
		
		if (inheritanceChain)
		{
			var types = EntityManager._types;
			while (e != null)
			{
				if (types.has(e._type << 16 | type)) break;
				e = e.sibling;
			}
		}
		else
		{
			while (e != null)
			{
				if (e._type == type) break;
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
	
	/**
	 * Sends a message to all entities of a given name.
	 */
	public function msgToName(name:String, type:Int)
	{
		var e = EntityManager.lookupByName(name);
		if (e == null) return;
		
		var q = EntityManager._msgQue;
		var k = e.length;
		while (k-- > 0)
			q.enqueue(this, e[k], type, k);
	}
	
	/**
	 * Sends a message to all ancestors.
	 */
	public function msgToAncestors(type:Int)
	{
		var q = EntityManager._msgQue;
		var e = parent;
		var k = depth;
		while (k-- > 0)
		{
			q.enqueue(this, e, type, k);
			e = e.parent;
		}
	}
	
	/**
	 * Sends a message to all descendants.
	 */
	public function msgToDescendants(type:Int)
	{
		var q = EntityManager._msgQue;
		var e = child;
		var k = size;
		while (k-- > 0)
		{
			q.enqueue(this, e, type, k);
			e = e.preorder;
		}
	}
	
	/**
	 * Sends a message to all children.
	 */
	public function msgToChildren(type:Int)
	{
		var q = EntityManager._msgQue;
		var e = child;
		var k = numChildren;
		while (k-- > 0)
		{
			q.enqueue(this, e, type, k);
			e = e.sibling;
		}
	}
	
	/**
	 * Sends a message to all siblings.
	 */
	public function msgToSiblings(type:Int)
	{
		if (parent != null) parent.msgToChildren(type);
	}
	
	/**
	 * Returns the root entity.
	 */
	public function getRoot():Entity
	{
		var e = parent;
		while (e.parent != null) e = e.parent;
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
		_bits |= BIT_STOP_PROPAGATION;
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
		return '{ Entity name: $name, type: ${ClassUtil.getUnqualifiedClassName(this)} }';
	}
	
	function onAdd()
	{
	}
	
	function onRemove()
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
	
	function onMsg(type:Int, sender:Entity)
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
}