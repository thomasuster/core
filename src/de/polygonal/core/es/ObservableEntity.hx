package de.polygonal.core.es;

import de.polygonal.ds.IntHashTable;

@:access(de.polygonal.core.es.EntityManager)
class ObservableEntity extends Entity
{
	var _observersByType:IntHashTable<Array<EntityId>>;
	
	public function new(name:String = null)
	{
		_observersByType = new IntHashTable<Array<EntityId>>(256, 1024);
		
		super(name);
	}
	
	override public function free()
	{
		super.free();
		
		_observersByType.free();
		_observersByType = null;
	}
	
	public function notify(type:Int)
	{
		var observers = _observersByType.get(type);
		if (observers == null) return;
		
		var q = EntityManager._msgQue;
		var k = observers.length;
		while (k-- > 0)
		{
			var id = observers[k];
			q.enqueue(this, EntityManager.lookup(id), type, k);
			if (id.inner < 0)
				observers.pop();
		}
	}
	
	public function attach(e:Entity, type:Int):Bool
	{
		var observers = _observersByType.get(type);
		if (observers == null)
		{
			observers = [];
			_observersByType.set(type, observers);
		}
		
		for (i in observers)
			if (i.equals(e.id)) return false;
		
		observers.push(e.id);
		
		return true;
	}
	
	public function detach(e:Entity, type:Int):Bool
	{
		var observers = _observersByType.get(type);
		if (observers == null) return false;
		var k = observers.length;
		for (i in 0...k)
		{
			if (observers[i].equals(e.id))
			{
				observers[i] = observers[k - 1];
				observers.pop();
				return true;
			}
		}
		
		return false;
	}
}