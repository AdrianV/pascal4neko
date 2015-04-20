package p4n.vcl;

/**
 * ...
 * @author 
 */

extern class TFormInterface extends TComponent {
	public function new(inOwner: TComponent) { super(inOwner);  }
	public function showModal(): Int;
}

class TForm extends TFormInterface
{

	public function new(inOwner: TComponent) 
	{
		TComponent.createPascalComponent("TForm", this, inOwner);
		super(inOwner);
	}
	
	// public var showModal: Void -> Int;
	
	#if false
	static function __init__(): Void {
		untyped TForm = TObject._classes.p4n.vcl.TForm;
	}
	#end
}