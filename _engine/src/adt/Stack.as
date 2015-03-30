package adt { // ADT: Abstract Data Type
public class Stack
{
	private var first:SimpleNode;
	public function push(data:Object):void
	{
		var temp:SimpleNode = first;
		first = new SimpleNode(data);
		first.next = temp;
	}
	public function pop():Object
	{
		var result:Object = first.data;
		first = first.next;
		return result;
	}
	public function peek():Object
	{
		return first.data;
	}
	public function isEmpty():Boolean
	{
		return first == null;
	}
}
}