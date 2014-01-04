package;

import de.polygonal.core.es.Entity;
import de.polygonal.core.es.EntitySystem;
import haxe.unit.TestCase;

using de.polygonal.core.es.EntityIterator;

@:access(de.polygonal.core.es.Entity)
@:access(de.polygonal.core.es.EntitySystem)
class TestEntityIterator extends TestCase
{
	public function new()
	{
		super();
		EntitySystem.init();
	}
	
	function testDescendants()
	{
		var a = new Entity('a');
		var b = new Entity('b');
		var c = new Entity('c');
		
		var result:Array<String> = [];
		
		for (e in a.descendants()) result.push(e.name);
		assertEquals("", result.join(""));
		result = [];
		
		a.add(b);
		
		for (e in a.descendants()) result.push(e.name);
		assertEquals("b", result.join(""));
		result = [];
		
		a.add(c);
		
		for (e in a.descendants()) result.push(e.name);
		assertEquals("bc", result.join(""));
	}
	
	function testAncestors()
	{
		var a = new Entity('a');
		var b = new Entity('b');
		var c = new Entity('c');
		
		var result:Array<String> = [];
		
		for (e in a.ancestors()) result.push(e.name);
		assertEquals("", result.join(""));
		result = [];
		
		a.add(b);
		
		for (e in b.ancestors()) result.push(e.name);
		assertEquals("a", result.join(""));
		result = [];
		
		b.add(c);
		
		for (e in c.ancestors()) result.push(e.name);
		assertEquals("ba", result.join(""));
	}
	
	function testSiblings()
	{
		var a = new Entity('a');
		var b = new Entity('b');
		var c = new Entity('c');
		var d = new Entity('d');
		
		var result:Array<String> = [];
		
		for (e in a.siblings()) result.push(e.name);
		assertEquals("", result.join(""));
		result = [];
		
		a.add(b);
		
		for (e in b.siblings()) result.push(e.name);
		assertEquals("", result.join(""));
		result = [];
		
		a.add(c);
		
		for (e in b.siblings()) result.push(e.name);
		assertEquals("c", result.join(""));
		result = [];
		
		for (e in c.siblings()) result.push(e.name);
		assertEquals("b", result.join(""));
		result = [];
		
		a.add(d);
		
		for (e in d.siblings()) result.push(e.name);
		assertEquals("bc", result.join(""));
		result = [];
		
		for (e in d.siblings()) result.push(e.name);
		assertEquals("bc", result.join(""));
		result = [];
		
		for (e in c.siblings()) result.push(e.name);
		assertEquals("bd", result.join(""));
		result = [];
		
		for (e in b.siblings()) result.push(e.name);
		assertEquals("cd", result.join(""));
	}
}