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
package de.polygonal.core.math;

import de.polygonal.core.math.Mathematics;
import haxe.ds.Vector;

/**
 * The median of a set of numbers.
 */
class Median
{
	var mNext:Int;
	var mSize:Int;
	var mCapacity:Int;
	var mValue:Float;
	var mSet:Vector<Float>;
	var mChanged:Bool;
	
	public function new(capacity:Int)
	{
		mSet = new Vector<Float>(mCapacity = capacity);
		for (i in 0...capacity) mSet[i] = 0;
		reset();
	}
	
	public var value(get_value, never):Float;
	inline function get_value():Float
	{
		if (mChanged) compute();
		return mValue;
	}
	
	inline public function reset()
	{
		mNext = 0;
		mSize = 0;
		mValue = 0;
		mChanged = true;
	}
	
	inline public function add(value:Float)
	{
		mSet.set(mNext, value);
		mNext = (mNext + 1) % mCapacity;
		mSize = mSize < mCapacity ? mSize + 1: mSize;
		mChanged = true;
	}
	
	function compute()
	{
		var k = mSize;
			
		//insertion sort
		for (i in 1...k)
		{
			var x = mSet.get(i);
			var j = i;
			while ((j > 0) && (mSet.get(j - 1) > x))
			{
				mSet.set(j, mSet.get(j - 1));
				j--;
			}
			mSet.set(j, x);
		}
		
		if (k == 0)
			mValue = 0;
		else
		{
			if (M.isEven(k))
			{
				if (k == 2)
					mValue = (mSet.get(0) + mSet.get(1)) * .5;
				else
					mValue = (mSet.get((k >> 1)) + mSet.get(((k >> 1)) - 1)) * .5;
			}
			else
				mValue =  mSet.get(k >> 1);
		}
	}
}