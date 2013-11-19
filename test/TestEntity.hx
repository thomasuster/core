package;

import de.polygonal.core.es.Entity;
import de.polygonal.core.es.EntitySystem;
import haxe.unit.TestCase;

using de.polygonal.core.es.EntityIterator;

@:access(de.polygonal.core.es.Entity)
@:access(de.polygonal.core.es.EntitySystem)
class TestEntity extends TestCase
{
	public function new()
	{
		super();
		EntitySystem.init();
	}
	
	function testSize()
	{
		var a = new Entity("a");
			var b = new Entity("b");
			var c = new Entity("c");
			var d = new Entity("d");
				var e = new Entity("e");
				var f = new Entity("f");
		
		a.add(b);
		a.add(c);
		a.add(d);
			d.add(e);
			d.add(f);
			
		assertEquals(a.size, 5);
		assertEquals(b.size, 0);
		assertEquals(c.size, 0);
		assertEquals(d.size, 2);
		assertEquals(e.size, 0);
		assertEquals(f.size, 0);
		
		var s = new Entity("s");
			var b = new Entity("b");
			var c = new Entity("c");
			var d = new Entity("d");
		s.add(b);
		s.add(c);
		s.add(d);
		
		var a = new Entity("a");
		a.add(s);
		
		assertEquals(a.size, 4);
		assertEquals(s.size, 3);
		assertEquals(b.size, 0);
		assertEquals(c.size, 0);
		assertEquals(d.size, 0);
	}
	
	function testGetChildAt()
	{
		var a = new E("a");
		var b = new E("b");
		var c = new E("c");
		var d = new E("d");
		
		a.add(b);
		assertEquals(a.getChildAt(0).name, "b");
		
		a.add(c);
		assertEquals(a.getChildAt(0).name, "b");
		assertEquals(a.getChildAt(1).name, "c");
		
		a.add(d);
		
		assertEquals(a.getChildAt(0).name, "b");
		assertEquals(a.getChildAt(1).name, "c");
		assertEquals(a.getChildAt(2).name, "d");
		
		a.free();
		b.free();
		c.free();
		d.free();
	}
	
	function testRemove1()
	{
		var a = new E("a");
		var b = new E("b");
		a.add(b);
		a.remove(b);
		assertEquals("a", printPreOrder(a));
		
		var a = new E("a");
		var b = new E("b");
		var c = new E("c");
		a.add(b);
		a.add(c);
		
		a.remove(c);
		assertEquals("a,b", printPreOrder(a));
		a.remove(b);
		assertEquals("a", printPreOrder(a));
	}
	
	function testRemove2()
	{
		var a = new E("a");
		var b = new E("b");
		var c = new E("c");
		a.add(b);
		b.add(c);
		
		assertEquals("a,b,c", printPreOrder(a));
		
		a.remove(b);
		assertEquals("a", printPreOrder(a));
		assertEquals("b,c", printPreOrder(b));
		
		var a = new E("a");
		var b = new E("b");
		var c = new E("c");
		a.add(b);
		b.add(c);
		var d = new E("d");
		a.add(d);
		assertEquals("a,b,c,d", printPreOrder(a));
		
		a.remove(b);
		assertEquals("a,d", printPreOrder(a));
		assertEquals("b,c", printPreOrder(b));
	}
	
	function testRemove3()
	{
		var a = new E("a");
		var b = new E("b");
		var c = new E("c");
		var d = new E("d");
		var e = new E("e");
		a.add(b);
			b.add(c);
		
		a.add(d);
			d.add(e);
		
		assertEquals("a,b,c,d,e", printPreOrder(a));
		
		a.remove(d);
		assertEquals("a,b,c", printPreOrder(a));
		assertEquals("d,e", printPreOrder(d));
		
		var a = new E("a");
		var b = new E("b");
		var c = new E("c");
		var d = new E("d");
		var e = new E("e");
		var f = new E("f");
		var g = new E("g");
		
		a.add(b);
			b.add(c);
		
		a.add(d);
			d.add(e);
		
		a.add(f);
			f.add(g);
		
		assertEquals("a,b,c,d,e,f,g", printPreOrder(a));
		
		a.remove(d);
		assertEquals("a,b,c,f,g", printPreOrder(a));
		assertEquals("d,e", printPreOrder(d));
	}
	
	function testUpdateLastChild()
	{
		var a = new Entity("a");
		var b = new Entity("b");
		var c = new Entity("c");
		
		a.add(b);
		assertEquals(a.lastChild, b);
		
		a.remove(b);
		assertEquals(a.lastChild, null);
		
		a.add(b);
		a.add(c);
		
		c.remove();
		assertEquals(a.lastChild, b);
		
		b.remove();
		assertEquals(a.lastChild, null);
		
		a.add(b);
		a.add(c);
		
		b.remove();
		assertEquals(a.lastChild, c);
	}
	
	function testChildIndex()
	{
		var a = new Entity("a");
		
		assertEquals(-1, a.getChildIndex());
		
		var b = new Entity("b");
		a.add(b);
		
		assertEquals(0, b.getChildIndex());
		
		var c = new Entity("c");
		a.add(c);
		
		assertEquals(0, b.getChildIndex());
		assertEquals(1, c.getChildIndex());
	}
	
	function testDepth()
	{
		var a = new Entity("a");
		var b = new Entity("b");
		
		assertEquals(a.depth, 0);
		assertEquals(b.depth, 0);
		
		a.add(b);
		
		assertEquals(a.depth, 0);
		assertEquals(b.depth, 1);
		
		var c = new Entity("c");
			b.add(c);
			
		var d = new Entity("d");
			c.add(d);
		
		assertEquals(a.depth, 0);
		assertEquals(b.depth, 1);
		assertEquals(c.depth, 2);
		assertEquals(d.depth, 3);
		
		b.remove(c);
		
		assertEquals(a.depth, 0);
		assertEquals(b.depth, 1);
		assertEquals(c.depth, 0);
		assertEquals(d.depth, 1);
		
		var a = new Entity("a");
		var s = new Entity("s");
			var b = new Entity("b");
		s.add(b);
		
		a.add(s);
		
		assertEquals(a.depth, 0);
		assertEquals(s.depth, 1);
		assertEquals(b.depth, 2);
		
		var a = new Entity("a");
		var s = new Entity("s");
			var b = new Entity("b");
			var c = new Entity("b");
		s.add(b);
		s.add(c);
		
		a.add(s);
		
		assertEquals(a.depth, 0);
		assertEquals(s.depth, 1);
		assertEquals(b.depth, 2);
		assertEquals(c.depth, 2);
	}
	
	function testMsgToDescendants1()
	{
		var result = [];
		Callback.onMsg = function(recipient:Entity, sender:Entity, type:Int)
		{
			result.push(sender.name + recipient.name + type);
		}
		
		var a = new E("a");
			var b = new E("b");
			var c = new E("c");
			var d = new E("d");
		
		a.add(b);
		a.add(c);
		a.add(d);
		
		a.msgToDescendants(3);
		
		EntitySystem.dispatchMessages();
		
		assertEquals(result.join(','), "ab3,ac3,ad3");
		
		Callback.onMsg = null;
	}
	
	function testMsgToDescendants2()
	{
		//send message from a => b,c,d but stop on b
		var result = [];
		Callback.onMsg = function(recipient:Entity, sender:Entity, type:Int)
		{
			result.push(sender.name + recipient.name + type);
		}
		
		var a = new E("a");
			var b = new E("b");
			var c = new E("c");
			var d = new E("d");
		
		a.add(b);
		a.add(c);
		a.add(d);
		
		a.msgToDescendants(3);
		
		b.onMsgFunc = function()
		{
			b.stop();
		}
		
		EntitySystem.dispatchMessages();
		
		assertEquals(result.join(','), "ab3");
		
		Callback.onMsg = null;
	}
	
	function testMsgToDescendants3()
	{
		//send message from a => b,c,d but stop on c
		var result = [];
		Callback.onMsg = function(recipient:Entity, sender:Entity, type:Int)
		{
			result.push(sender.name + recipient.name + type);
		}
		
		var a = new E("a");
			var b = new E("b");
			var c = new E("c");
			var d = new E("d");
		
		a.add(b);
		a.add(c);
		a.add(d);
		
		a.msgToDescendants(3);
		
		c.onMsgFunc = function()
		{
			c.stop();
		}
		
		EntitySystem.dispatchMessages();
		
		assertEquals(result.join(','), "ab3,ac3");
		
		Callback.onMsg = null;
	}
	
	function testMsgToDescendants4()
	{
		//send message from a => b,c,d but stop on d
		var result = [];
		Callback.onMsg = function(recipient:Entity, sender:Entity, type:Int)
		{
			result.push(sender.name + recipient.name + type);
		}
		
		var a = new E("a");
			var b = new E("b");
			var c = new E("c");
			var d = new E("d");
		
		a.add(b);
		a.add(c);
		a.add(d);
		
		a.msgToDescendants(3);
		
		d.onMsgFunc = function()
		{
			d.stop();
		}
		
		a.msgToDescendants(4);
		
		EntitySystem.dispatchMessages();
		
		assertEquals(result.join(','), "ab3,ac3,ad3,ab4,ac4,ad4");
		
		Callback.onMsg = null;
	}
	
	function testMsgToAncestors()
	{
		//send message from c => b,a
		var result = [];
		Callback.onMsg = function(recipient:Entity, sender:Entity, type:Int)
		{
			result.push(sender.name + recipient.name + type);
		}
		
		var a = new E("a");
			var b = new E("b");
				var c = new E("c");
		
		a.add(b);
		b.add(c);
		
		c.msgToAncestors(3);
		EntitySystem.dispatchMessages();
		
		assertEquals(result.join(','), "cb3,ca3");
		
		result = [];
		b.onMsgFunc = function()
		{
			b.stop();
		}
		c.msgToAncestors(3);
		EntitySystem.dispatchMessages();
		assertEquals(result.join(','), "cb3");
		
		result = [];
		b.onMsgFunc = function() {}
		c.onMsgFunc = function()
		{
			c.stop();
		}
		c.msgToAncestors(3);
		EntitySystem.dispatchMessages();
		assertEquals(result.join(','), "cb3,ca3");
		
		Callback.onMsg = null;
	}
	
	function testMsgToChildren()
	{
		//send message from a => b,c,d
		var result = [];
		Callback.onMsg = function(recipient:Entity, sender:Entity, type:Int)
		{
			result.push(sender.name + recipient.name + type);
		}
		
		var a = new E("a");
			var b = new E("b");
			var c = new E("c");
			var d = new E("d");
		
		a.add(b);
		a.add(c);
		a.add(d);
		
		a.msgToChildren(3);
		EntitySystem.dispatchMessages();
		
		result = [];
		b.onMsgFunc = function()
		{
			b.stop();
		}
		a.msgToChildren(3);
		EntitySystem.dispatchMessages();
		
		assertEquals(result.join(','), "ab3");
		
		result = [];
		b.onMsgFunc = function() {}
		c.onMsgFunc = function()
		{
			c.stop();
		}
		a.msgToChildren(3);
		EntitySystem.dispatchMessages();
		
		assertEquals(result.join(','), "ab3,ac3");
		
		Callback.onMsg = null;
	}
	
	function testMsgToName()
	{
		var result = [];
		Callback.onMsg = function(recipient:Entity, sender:Entity, type:Int)
		{
			result.push(sender.name + recipient.name + type);
		}
		
		var a1 = new E("y");
		var a2 = new E("y");
		var b1 = new E("z");
		var b2 = new E("z");
		
		a1.msgTo("z", 3);
		EntitySystem.dispatchMessages();
		
		assertEquals(result.join(','), "yz3,yz3");
		
		result = [];
		b1.msgTo("y", 3);
		EntitySystem.dispatchMessages();
		assertEquals(result.join(','), "zy3,zy3");
		
		Callback.onMsg = null;
	}
	
	function testAdd1()
	{
		var a = new E("a");
		var b = new E("b");
		a.add(b);
		
		assertEquals("a,b", printPreOrder(a));
		
		var a = new E("a");
		var b = new E("b");
		var c = new E("c");
		a.add(b);
		a.add(c);
		assertEquals("a,b,c", printPreOrder(a));
		
		var a = new E("a");
		var b = new E("b");
		a.add(b);
		assertEquals("a,b", printPreOrder(a));
		
		var c = new E("c");
		var d = new E("d");
		c.add(d);
		assertEquals("c,d", printPreOrder(c));
		
		a.add(c);
		assertEquals("a,b,c,d", printPreOrder(a));
	}
	
	function testAdd2()
	{
		var r = new E("r");
			var a = new E("a");
				var c = new E("c");
				a.add(c);
			r.add(a);
		assertEquals("r,a,c", printPreOrder(r));
	}
	
	function testAdd3()
	{
		var r = new E("r");
			var a = new E("a");
				var c = new E("c");
				a.add(c);
			r.add(a);
			var b = new E("b");
			r.add(b);
		assertEquals("r,a,c,b", printPreOrder(r));
	}
	
	function testAddRemove1()
	{
		var r = new E("r");
		
		var bag = new E("bag");
		
		var a = new E("a");
		var b = new E("b");
		
		var t = new E("t");
		
		r.add(bag);
		bag.add(a);
		bag.add(b);
		
		assertEquals("r,bag,a,b", printPreOrder(r));
		
		a.remove();
		
		assertEquals("r,bag,b", printPreOrder(r));
		
		r.add(a);
		
		assertEquals("r,bag,b,a", printPreOrder(r));
	}
	
	function testAddOnRemove()
	{
		var a = new E("a");
		var b = new E("b");
		
		b.onRemoveFunc = function()
		{
			a.add(b);
			
			assertEquals(1, a.size);
			assertEquals(a.child, b);
			assertEquals(b.parent, a);
			assertEquals("a,b", printPreOrder(a));
			assertEquals("b", printPreOrder(b));
		}
		
		a.add(b);
		a.remove(b);
	}
	
	function testRemoveOnAdd()
	{
		var a = new E("a");
		var b = new E("b");
		
		b.onAddFunc = function()
		{
			a.remove(b);
			
			assertEquals(0, a.size);
			assertEquals(a.child, null);
			assertEquals(b.parent, null);
			assertEquals("a", printPreOrder(a));
			assertEquals("b", printPreOrder(b));
		}
		
		a.add(b);
	}
	
	function testRemoveAllChildren()
	{
		var r = new E("r");
			var a = new E("a");
				var b = new E("b");
					var c = new E("c");
					
		var d = new E("d");
			var e = new E("e");
		r.add(a);
			a.add(b);
				b.add(c);
				
		r.add(d);
			d.add(e);
		
		r.removeAllChildren();
		
		assertEquals(r.child, null);
		
		assertEquals(b.preorder, c);
		assertEquals(c.preorder, null);
		assertEquals(d.preorder, e);
		assertEquals(e.preorder, null);
	}
	
	function testSetFirst()
	{
		var r = new E("r");
			var a = new E("a");
		r.add(a);
		
		a.setFirst();
		
		assertEquals(r.child, a);
		
		var r = new E("r");
			var a = new E("a");
			var b = new E("b");
		r.add(a);
		r.add(b);
		
		b.setFirst();
		
		assertEquals(r.child, b);
		assertEquals(b.sibling, a);
		assertEquals(a.sibling, null);
		
		var r = new E("r");
			var a = new E("a");
			var b = new E("b");
			var c = new E("c");
		r.add(a);
		r.add(b);
		r.add(c);
		
		assertEquals("r,a,b,c", printPreOrder(r));
		
		assertEquals(c.sibling, null);
		
		b.setFirst();
		
		assertEquals("r,b,a,c", printPreOrder(r));
		assertEquals(b.sibling, a);
		assertEquals(a.sibling, c);
		assertEquals(c.sibling, null);
		assertEquals(r.preorder, b);
		assertEquals(b.preorder, a);
		assertEquals(a.preorder, c);
		assertEquals(c.preorder, null);
		
		var r = new E("r");
			var a = new E("a");
			var b = new E("b");
			var c = new E("c");
		r.add(a);
		r.add(b);
		r.add(c);
		
		assertEquals("r,a,b,c", printPreOrder(r));
		
		c.setFirst();
		
		assertEquals("r,c,a,b", printPreOrder(r));
		assertEquals(c.sibling, a);
		assertEquals(a.sibling, b);
		assertEquals(b.sibling, null);
	}
	
	function testSetLast()
	{
		var r = new E("r");
			var a = new E("a");
		r.add(a);
		
		a.setLast();
		
		assertEquals(r.child, a);
		
		var r = new E("r");
			var a = new E("a");
			var b = new E("b");
		r.add(a);
		r.add(b);
		
		a.setLast();
		
		assertEquals(r.child, b);
		assertEquals(b.sibling, a);
		assertEquals(a.sibling, null);
		
		assertEquals("r,b,a", printPreOrder(r));
		
		var r = new E("r");
			var a = new E("a");
			var b = new E("b");
			var c = new E("c");
		r.add(a);
		r.add(b);
		r.add(c);
		
		assertEquals("r,a,b,c", printPreOrder(r));
		
		b.setLast();
		
		assertEquals("r,a,c,b", printPreOrder(r));
		assertEquals(a.sibling, c);
		assertEquals(c.sibling, b);
		assertEquals(b.sibling, null);
		
		assertEquals(a.preorder, c);
		assertEquals(c.preorder, b);
		assertEquals(b.preorder, null);
		assertEquals(r.preorder, a);
		assertEquals(r.child, a);
		
		var r = new E("r");
			var s = new E("s");
				var a = new E("a");
				var b = new E("b");
				var c = new E("c");
			s.add(a);
			s.add(b);
			s.add(c);
		r.add(s);
		
		var d = new E("d");
		r.add(d);
			
		assertEquals("r,s,a,b,c,d", printPreOrder(r));
		
		b.setLast();
		assertEquals("r,s,a,c,b,d", printPreOrder(r));
		assertEquals(a.sibling, c);
		assertEquals(c.sibling, b);
		assertEquals(b.sibling, null);
		
		assertEquals(a.preorder, c);
		assertEquals(c.preorder, b);
		assertEquals(b.preorder, d);
		assertEquals(r.preorder, s);
		assertEquals(r.child, s);
		assertEquals(s.preorder, a);
		
		var r = new E("r");
			var a = new E("a");
			var b = new E("b");
		r.add(a);
		r.add(b);
		assertEquals("r,a,b", printPreOrder(r));
		a.setLast();
		assertEquals("r,b,a", printPreOrder(r));
		
		assertEquals(r.child, b);
		assertEquals(b.sibling, a);
		assertEquals(a.sibling, null);
		
		assertEquals(r.preorder, b);
		assertEquals(b.preorder, a);
		assertEquals(a.preorder, null);
	}
	
	function printPreOrder(e:Entity):String
	{
		var a = [];
		while (e != null)
		{
			a.push(e.name);
			e = e.preorder;
		}
		return a.join(',');
	}
}

private class Callback
{
	public static var onAdd:Entity->Entity->Void = null;
	public static var onRemove:Entity->Entity->Void = null;
	public static var onTick:Entity->Void = null;
	public static var onMsg:Entity->Entity->Int->Void = null;
	public static var onFree:Entity->Void;
}

private class E extends Entity
{
	public var onTickFunc:Void->Void;
	public var onAddFunc:Void->Void;
	public var onRemoveFunc:Void->Void;
	public var onMsgFunc:Void->Void;
	public var onFreeFunc:Void->Void;
	
	public function new(name:String)
	{
		super(name);
		onTickFunc = function() {};
		onAddFunc = function() {};
		onRemoveFunc = function() {};
		onMsgFunc = function() {};
		onFreeFunc = function() {};
	}
	
	override function onTick(dt:Float)
	{
		if (Callback.onTick != null) Callback.onTick(this);
		onTickFunc();
	}
	
	override function onAdd()
	{
		if (Callback.onAdd != null) Callback.onAdd(this, parent);
		onAddFunc();
	}
	
	override function onRemove(parent:Entity)
	{
		if (Callback.onRemove != null) Callback.onRemove(this, parent);
		onRemoveFunc();
	}
	
	override function onMsg(type:Int, sender:Entity)
	{
		if (Callback.onMsg != null) Callback.onMsg(this, sender, type);
		onMsgFunc();
	}
	
	override function onFree()
	{
		if (Callback.onFree != null) Callback.onFree(this);
		onFreeFunc();
	}
}