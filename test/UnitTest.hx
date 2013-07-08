import de.polygonal.core.log.handler.TraceHandler;
import flash.Boot;
import flash.text.TextFormat;

class UnitTest extends haxe.unit.TestRunner
{
	public static function main():Void
	{
		new UnitTest();
	}
	
	public function new()
	{
		super();
		
		var output = '\n';
		haxe.unit.TestRunner.print = function(v:Dynamic):Dynamic { output += Std.string(v); }
		
		add(new TestSprintf());
		add(new TestRLE());
		
		run();
		
		trace(output);
	}
}