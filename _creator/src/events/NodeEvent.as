package events {
import flash.events.Event;

public class NodeEvent extends Event
{
	public static const NODES_ADDED:String = 'nodesAdded';
	public static const NODES_REMOVED:String = 'nodesRemoved';
	public static const NODES_REPLACED:String = 'nodesReplaced';
	public static const NODES_PREPENDED:String = 'nodesPrepended';
	
	public function NodeEvent(type:String, bubbles:Boolean = false, cancelable:Boolean = false)
	{
		super(type, bubbles, cancelable);
	}
	/**
	 * Creates a exact copy of this event (hotspot will be copied by reference)
	 */
	public override function clone():Event
	{
		return new NodeEvent(type, bubbles, cancelable);
	}
}
}