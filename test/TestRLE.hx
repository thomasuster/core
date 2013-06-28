import de.polygonal.core.io.RLE;
import haxe.io.BytesInput;
import haxe.unit.TestCase;
import haxe.io.Bytes;

class TestRLE extends TestCase
{
	public function test()
	{
		assertEquals("", RLE.encodeString(""));
		assertEquals("A", RLE.encodeString("A"));
		assertEquals("", RLE.decodeString(Bytes.ofString("")));
	}
	
	public function testRoundTrip()
	{
		var randomString = "aaaabbbcdDabQ";
		assertEquals(randomString, RLE.decodeString(RLE.encodeString(randomString)));
	}
}