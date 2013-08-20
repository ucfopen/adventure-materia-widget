package {
import flash.geom.Point;
import hotspots.AdventureHotspot;
public class AdventureUtils
{
	public static function encodeHotspot(hotspot:AdventureHotspot):String
	{
		return hotspot.isDefault ? "default" : hotspot.type + hotspot.points.toString();
	}
	public static function decodeHotspot(hotspot:String):AdventureHotspot
	{
		if(hotspot == "default")
		{
			var result:AdventureHotspot = new AdventureHotspot(0, []);
			result.isDefault = true;
			return result;
		}
		else
		{
			var type:int = int(hotspot.substr(0, 1));
			var code:String = hotspot.substr(1);
			var pointsFinal:Array;
			if(type == AdventureOptions.HOTSPOT_POLYGON)
			{
				var pointsRaw:Array = code.substring(1, code.length - 1).split("),(");
				pointsFinal = new Array();
				for(var i:int = 0; i < pointsRaw.length; i++)
				{
					var s:String = pointsRaw[i];
					var commaPos:int = pointsRaw[i].indexOf(',');
					var p1:String = s.substring(s.indexOf('=') + 1, s.indexOf(','));
					var p2:String = s.substring(s.indexOf('=', 2) + 1);
					pointsFinal.push(new Point(int(p1), int(p2)));
				}
			}
			else
			{
				pointsFinal = code.split(',');
			}
			return new AdventureHotspot(type, pointsFinal);
		}
	}
}
}