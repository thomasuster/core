import de.polygonal.core.fmt.Sprintf;
import haxe.unit.TestCase;

class TestSprintf extends TestCase
{
	public function test()
	{
		assertEquals('[', Sprintf.format('[', []));
		assertEquals('%', Sprintf.format('%%', []));
	}
	
	public function testgG()
	{
		assertEquals('[1.230e+002]', Sprintf.format('[%.3e]', [123.0]));
		assertEquals('[123.000]', Sprintf.format('[%.3f]', [123.0]));
		
		assertEquals('[123]', Sprintf.format('[%g]', [123.0]));
		
		//TODO shorter of e, f
		//assertEquals('[123.000]', Sprintf.format('[%#g]', [123.0]));
		//assertEquals('[123.000 123]', Sprintf.format('[%#g %g]', [123.0, 123.0]));
	}
	
	public function testxX()
	{
		assertEquals('[50]', Sprintf.format('[%x]', [80]));
		assertEquals('[0x50]', Sprintf.format('[%#x]', [80]));
		assertEquals('[50]', Sprintf.format('[%X]', [80]));
		assertEquals('[0X50]', Sprintf.format('[%#X]', [80]));
		assertEquals('[0]', Sprintf.format('[%x]', [0]));
		assertEquals('[0]', Sprintf.format('[%X]', [0]));
		assertEquals('[0]', Sprintf.format('[%#x]', [0]));
		assertEquals('[0]', Sprintf.format('[%#X]', [0]));
	}
	
	public function testeE()
	{
		var s = Sprintf.format('[%.3e]', [0.00001133]);
		assertEquals('[1.133e-005]', s);
		var s = Sprintf.format('[%.6e]', [0.00001133]);
		assertEquals('[1.133000e-005]', s);
		var s = Sprintf.format('[%e]', [0.00001133]);
		assertEquals('[1.133000e-005]', s);
		
		var s = Sprintf.format('[%.3e]', [-0.00001133]);
		assertEquals('[-1.133e-005]', s);
		var s = Sprintf.format('[%.6e]', [-0.00001133]);
		assertEquals('[-1.133000e-005]', s);
		var s = Sprintf.format('[%e]', [-0.00001133]);
		assertEquals('[-1.133000e-005]', s);
		
		var s = Sprintf.format('[%.3e]', [123.123456]);
		assertEquals('[1.231e+002]', s);
		var s = Sprintf.format('[%.6e]', [123.123456]);
		assertEquals('[1.231235e+002]', s);
		var s = Sprintf.format('[%e]', [123.123456]);
		assertEquals('[1.231235e+002]', s);
		
		var s = Sprintf.format('[%.3e]', [-123.123456]);
		assertEquals('[-1.231e+002]', s);
		var s = Sprintf.format('[%.6e]', [-123.123456]);
		assertEquals('[-1.231235e+002]', s);
		var s = Sprintf.format('[%e]', [-123.123456]);
		assertEquals('[-1.231235e+002]', s);
		
		var s = Sprintf.format('[%+.3e]', [123.123456]);
		assertEquals('[+1.231e+002]', s);
		
		//todo test #, pad 0,space, left align
	}
	
	public function testdi()
	{
		assertEquals('[001]' , Sprintf.format('[%.3d]', [1]));
		assertEquals('[+001]' , Sprintf.format('[%+.3d]', [1]));
		assertEquals('[100]', Sprintf.format('[%.3d]', [100]));
		assertEquals('[10000]', Sprintf.format('[%.3d]', [10000]));
		assertEquals('[+]' , Sprintf.format('[%+.0d]', [0]));
		assertEquals('[]', Sprintf.format('[%.0d]', [0]));
		
		var s = Sprintf.format('integer [%.d]', [0]);
		assertEquals('integer []', s);
		
		var s = Sprintf.format('integer [%+.d]', [0]);
		assertEquals('integer [+]', s);
		
		var s = Sprintf.format('integer [%5.3d]', [5]);
		assertEquals('integer [  005]', s);
		
		var s = Sprintf.format('integer [%5.5d]', [5]);
		assertEquals('integer [00005]', s);
		
		var s = Sprintf.format('integer [%5.6d]', [5]);
		assertEquals('integer [000005]', s);
		
		var s = Sprintf.format('integer [%5.3d]', [-5]);
		assertEquals('integer [ -005]', s);
		
		var s = Sprintf.format('integer [%5.5d]', [-5]);
		assertEquals('integer [-00005]', s);
		
		var s = Sprintf.format('integer [%5.6d]', [-5]);
		assertEquals('integer [-000005]', s);
		
		//+5
		
		var s = Sprintf.format('integer [%d]', [5]);
		assertEquals('integer [5]', s);
		
		var s = Sprintf.format('integer [%5d]', [5]);
		assertEquals('integer [    5]', s);
		
		var s = Sprintf.format('integer [%-5d]', [5]);
		assertEquals('integer [5    ]', s);
		
		var s = Sprintf.format('integer [%-+5d]', [5]);
		assertEquals('integer [+5   ]', s);
		
		var s = Sprintf.format('integer [%05d]', [5]);
		assertEquals('integer [00005]', s);
		
		var s = Sprintf.format('integer [%-05d]', [5]);
		assertEquals('integer [5    ]', s);
		
		var s = Sprintf.format('integer [%-+05d]', [5]);
		assertEquals('integer [+5   ]', s);
		
		//-5
		
		var s = Sprintf.format('integer [%d]', [-5]);
		assertEquals('integer [-5]', s);
		
		var s = Sprintf.format('integer [%5d]', [-5]);
		assertEquals('integer [   -5]', s);
		
		var s = Sprintf.format('integer [%-5d]', [-5]);
		assertEquals('integer [-5   ]', s);
		
		var s = Sprintf.format('integer [%-+5d]', [-5]);
		assertEquals('integer [-5   ]', s);
		
		var s = Sprintf.format('integer [%05d]', [-5]);
		assertEquals('integer [-0005]', s);
		
		var s = Sprintf.format('integer [%-05d]', [-5]);
		assertEquals('integer [-5   ]', s);
		
		var s = Sprintf.format('integer [%-+05d]', [-5]);
		assertEquals('integer [-5   ]', s);
		
		//12345
		
		s = Sprintf.format('integer [%d]', [12345]);
		assertEquals('integer [12345]', s);
		
		s = Sprintf.format('integer [%5d]', [12345]);             
		assertEquals('integer [12345]', s);
		
		s = Sprintf.format('integer [%-5d]', [12345]);            
		assertEquals('integer [12345]', s);
		
		s = Sprintf.format('integer [%-+5d]', [12345]);
		assertEquals('integer [+12345]', s);
		
		s = Sprintf.format('integer [%05d]', [12345]);
		assertEquals('integer [12345]', s);
		
		s = Sprintf.format('integer [%-05d]', [12345]);
		assertEquals('integer [12345]', s);
		
		s = Sprintf.format('integer [%-+05d]', [12345]); 
		assertEquals('integer [+12345]', s);
		
		//-12345
		
		s = Sprintf.format('integer [%d]', [-12345]);
		assertEquals('integer [-12345]', s);
		
		s = Sprintf.format('integer [%5d]', [-12345]);             
		assertEquals('integer [-12345]', s);
		
		s = Sprintf.format('integer [%-5d]', [-12345]);            
		assertEquals('integer [-12345]', s);
		
		s = Sprintf.format('integer [%-+5d]', [-12345]);
		assertEquals('integer [-12345]', s);
		
		s = Sprintf.format('integer [%05d]', [-12345]);
		assertEquals('integer [-12345]', s);
		
		s = Sprintf.format('integer [%-05d]', [-12345]);
		assertEquals('integer [-12345]', s);
		
		s = Sprintf.format('integer [%-+05d]', [-12345]); 
		assertEquals('integer [-12345]', s);
	}
	
	public function testcs()
	{
		assertEquals('string [bla]', Sprintf.format('string [%s]', ['bla']));
		assertEquals('string [Hel]', Sprintf.format('string [%.3s]', ['Hello']));
		assertEquals('string [  bla]', Sprintf.format('string [%5s]', ['bla']));
		assertEquals('string [bla  ]', Sprintf.format('string [%-5s]', ['bla']));
		assertEquals('string [blabla]', Sprintf.format('string [%-5s]', ['blabla']));
		assertEquals('string [C]', Sprintf.format('string [%c]', [67]));
		assertEquals('string [    C]', Sprintf.format('string [%5c]', [67]));
	}
	
	public function testf()
	{
		//%+.3f negative number inserts +-
		
		assertEquals('0.000000', Sprintf.format('%f', [0]));
		assertEquals('0.000000', Sprintf.format('%f', [0.0]));
		assertEquals('1.000000', Sprintf.format('%f', [1]));
		assertEquals('1.000000', Sprintf.format('%f', [1.0]));
		
		assertEquals('1.000', Sprintf.format('%.3f', [1]));
		assertEquals('1.0', Sprintf.format('%.1f', [1]));
		assertEquals('1', Sprintf.format('%.f', [1]));
		assertEquals('2', Sprintf.format('%.f', [1.6]));
		assertEquals('1', Sprintf.format('%.f', [1.3]));
		
		assertEquals('2.', Sprintf.format('%#.f', [1.6]));
		assertEquals('1.', Sprintf.format('%#.f', [1.3]));
		
		assertEquals('     1.600', Sprintf.format('%#10.3f', [1.6]));
		assertEquals('     1.300', Sprintf.format('%#10.3f', [1.3]));
		//assertEquals('-00001.600', Sprintf.format('%010.3f', [-1.6])); //TODO bug
		//assertEquals('-1.600    ', Sprintf.format('%-010.3f', [-1.6])); //TODO bug
		//assertEquals('[-1.600    ]', Sprintf.format('[%-010.3f]', [-1.6])); //TODO bug
		assertEquals('1.300     ', Sprintf.format('%-10.3f', [1.3]));
		
		assertEquals('[+1.100]', Sprintf.format('[%+.3f]', [1.1]));
		assertEquals('[    +1.100]', Sprintf.format('[%+10.3f]', [1.1]));
		assertEquals('[+1.100000]', Sprintf.format('[%+f]', [1.1]));
		assertEquals('[+1]', Sprintf.format('[%+.f]', [1.1]));
		assertEquals('[ +1.100000]', Sprintf.format('[%+10f]', [1.1]));
		assertEquals('[        +1]', Sprintf.format('[%+10.f]', [1.1]));
		assertEquals('[+1.100]', Sprintf.format('[%-+.3f]', [1.1]));
		assertEquals('[+1.100    ]', Sprintf.format('[%-+10.3f]', [1.1]));
		assertEquals('[+1.100000]', Sprintf.format('[%-+f]', [1.1]));
		assertEquals('[+1]', Sprintf.format('[%-+.f]', [1.1]));
		assertEquals('[+1.100000 ]' , Sprintf.format('[%-+10f]', [1.1]));
		assertEquals('[+1        ]' , Sprintf.format('[%-+10.f]', [1.1]));

		assertEquals('[ 1.100]', Sprintf.format('[% .3f]', [1.1]));
		assertEquals('[     1.100]', Sprintf.format('[% 10.3f]', [1.1]));
		assertEquals('[ 1.100000]', Sprintf.format('[% f]', [1.1]));
		assertEquals('[ 1]', Sprintf.format('[% .f]', [1.1]));
		assertEquals('[  1.100000]', Sprintf.format('[% 10f]', [1.1]));
		assertEquals('[         1]', Sprintf.format('[% 10.f]', [1.1]));
	}
}