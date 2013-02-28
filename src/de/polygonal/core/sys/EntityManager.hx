package de.polygonal.core.sys;

import de.polygonal.core.util.Assert;

#if haxe3
import haxe.ds.StringMap in Hash;
import haxe.ds.IntMap in IntHash;
#end

class EntityManager
{
	static var _initialized = false;
	static var _keyLookup:Hash<Int> = null;
	static var _nextKey = 0;
	static var _scratchArr:Array<Entity> = null;
	
	static var _entitiesById:IntHash<Array<Entity>> = null;
	
	public static function registerEntity(e:Entity):Void
	{
		if (!_initialized)
		{
			_initialized = true;
			_entitiesById = new IntHash();
			_keyLookup = new Hash();
			_scratchArr = [];
		}
		
		if (_keyLookup.exists(e.id))
		{
			//resolve integer key from entity id
			var key = _keyLookup.get(e.id);
			_entitiesById.get(key).push(e);
		}
		else
		{
			//generate integer key for entity id
			var key = ++_nextKey;
			_keyLookup.set(e.id, key);
			_entitiesById.set(key, [e]);
		}
	}
	
	public static function unregisterEntity(e:Entity):Void
	{
		if (!_keyLookup.exists(e.id)) return;
		var key = _keyLookup.get(e.id);
		var a = _entitiesById.get(key);
		var success = a.remove(e);
		if (!success) throw 'error unregistering entity';
	}
	
	public static function resolveEntity(id:String):Entity
	{
		var key = _keyLookup.get(id);
		return _entitiesById.get(key)[0];
	}
	
	public static function sendMsg(sender:Entity, receiverId:String, msg:String, userData:Dynamic):Void
	{
		#if debug
		D.assert(_keyLookup.exists(receiverId), 'entity is not registered');
		#end
		
		var key = _keyLookup.get(receiverId);
		for (i in _entitiesById.get(key))
			i.onMsg(msg, sender, userData);
	}
}