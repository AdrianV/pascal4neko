package p4n.vcl;

/**
 * ...
 * @author 
 */
class TButton extends TComponent
{

	public function new(inOwner: TComponent) 
	{
		TComponent.createPascalComponent("TButton", this, inOwner);
		super(inOwner);
	}
	
}