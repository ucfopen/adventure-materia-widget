package hotspots {
public class AdventureHotspot
{
	/**
	 * The type of hotspot this is. See AdventureOptions
	 */
	public var type:int;
	/**
	 * The points that this hotspot consists of.
	 */
	public var points:Array;
	/**
	 * True if this is a hotspot that is activated whenever "no" hotspot is clicked
	 */
	public var isDefault:Boolean = false;
	/**
	 * Constructor
	 */
	public function AdventureHotspot(type:int, points:Array)
	{
		this.type = type;
		this.points = points;
	}
}
}