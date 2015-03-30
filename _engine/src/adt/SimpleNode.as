package adt {
public class SimpleNode
{
	public var next:SimpleNode;
	public var data:Object;
	public function SimpleNode(data:Object = null)
	{
		this.data = data;
	}
}
}