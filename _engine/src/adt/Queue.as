package adt {
public class Queue
{
	private var first:SimpleNode;
	private var last:SimpleNode;
	public function enqueue(data:Object):void
	{
		var newNode:SimpleNode = new SimpleNode(data);
		if(isEmpty())
		{
			first = newNode;
			last  = newNode;
		}
		else
		{
			last.next = newNode;
			last = newNode;
		}
	}
	public function dequeue():Object
	{
		if(isEmpty())
		{
			return null;
		}
		var result:Object = first.data;
		first = first.next;
		return result;
	}
	public function peek():Object
	{
		if(isEmpty())
		{
			return null;
		}
		return first;
	}
	public function isEmpty():Boolean
	{
		return first == null;
	}
}
}