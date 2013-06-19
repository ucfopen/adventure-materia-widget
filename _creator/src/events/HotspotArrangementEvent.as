package events {
import flash.events.Event;
import hotspots.AdventureDisplayHotspot;
public class HotspotArrangementEvent extends Event
{
	public static const ARRANGE_UP:String = "arrangeUp";
	public static const ARRANGE_DOWN:String = "arrangeDown";
	private var _hotspot:AdventureDisplayHotspot;
	/**
	 * HotpsotLayerEvent
	 * An event to used to instigate the change of layer position of a hotspot.
	 */
	public function HotspotArrangementEvent(type:String, hotspot:AdventureDisplayHotspot, bubbles:Boolean = false, cancelable:Boolean = false)
	{
		_hotspot = hotspot;
		super(type, bubbles, cancelable);
	}
	/**
	 * Creates a exact copy of this event (hotspot will be copied by reference)
	 */
	public override function clone():Event
	{
		return new HotspotArrangementEvent(type, _hotspot, bubbles, cancelable);
	}
	/**
	 * Returns a string representation of this Event
	 */
	public override function toString():String
	{
		return formatToString("HotspotLayerEvent", "type", "_hotspot", "bubbles", "cancelable", "eventPhase");
	}
	/**
	 * Getter for target hotspot to change layers for
	 */
	public function get hotspot():AdventureDisplayHotspot
	{
		return _hotspot;
	}
}
}