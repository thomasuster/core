import haxe.unit.TestRunner;

class UnitTest extends haxe.unit.TestRunner
{
	public static function main():Void
	{
		new UnitTest();
	}
	
	public function new()
	{
		super();
		
		add(new TestMersenne());
		run();
	}
}