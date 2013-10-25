package de.polygonal.core.es;

class EntityId
{
	public var index:Int;
	public var inner:Int;
	
	public function new() {}
	
	inline public function equals(other:EntityId):Bool
		return index == other.index && inner == other.inner;
}