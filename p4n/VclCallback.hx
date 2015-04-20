package p4n;

/**
 * ...
 * @author 
 */

class VclCallback<T>
{

	var _method: T;
	public function new(callback: T) 
	{
		_method = callback;
	}
	
	public function call(args: Array<Dynamic>) {
		return Reflect.callMethod(null, _method, args);
	}
}

typedef TNotifyEvent = VclCallback<Dynamic->Void>;
