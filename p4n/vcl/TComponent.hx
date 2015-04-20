package p4n.vcl;

/**
 * ...
 * @author 
 */

import p4n.TObject;

class TComponent extends TObject
{

	public var owner(default, null): TComponent;
	
	public function new(inOwner: TComponent) 
	{
		createPascalComponent("TComponent", this, inOwner);
		owner = inOwner;
	}
	
	
	static public var createPascalComponent: String-> TComponent -> TComponent -> Void = neko.Lib.load("$vcl", 'createPascalComponent', 3);  
}