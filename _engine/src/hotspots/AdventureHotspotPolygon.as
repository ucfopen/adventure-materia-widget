package hotspots {
	import flash.display.CapsStyle;
	import flash.display.DisplayObject;
	import flash.display.JointStyle;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import nm.draw.Color;
	import AdventureOptions;
	public class AdventureHotspotPolygon extends AdventureDisplayHotspot
	{
		public static var CONNECTED:String = "Polygon-Connected";
		protected const ANCHOR_STROKE_THICKNESS:int = 2;
		protected const ANCHOR_STROKE_COLOR:int = 0xffffff;
		protected const ANCHOR_FILL_COLOR:int = 0x8cdaff;
		protected var lastMouse:Point = new Point(0, 0);
		protected var points:Vector.<Point> = new Vector.<Point>();
		protected var anchorSprite:Sprite = new Sprite();
		public function AdventureHotspotPolygon(targetImage:DisplayObject, draggable:Boolean = true, visibility:int = AdventureOptions.VISIBILITY_ALWAYS)
		{
			trace("AdventureHotspotPolygon::constructor");
			super(targetImage, draggable, visibility);
			type = AdventureOptions.HOTSPOT_POLYGON;
			this.addChild(anchorSprite);
		}
		public override function redraw():void
		{
			super.redraw();
			drawPolygon(true);
		}
		public override function onMouseMoveCreate(e:MouseEvent):void
		{
			super.onMouseMoveCreate(e);
			lastMouse = this.globalToLocal(new Point(e.stageX, e.stageY));
			drawPolygon(false);
		}
		public function addPoint(e:MouseEvent):void
		{
			trace("AdventureHotspotPolygon::addPoint");
			// Track mouse position
			lastMouse = this.globalToLocal(new Point(e.stageX, e.stageY));
			// Check if this point collides with an existing one (finished polygon)
			for each(var p:Point in points)
			{
				if(mouseColissionCheck(p.x, p.y))
				{
					dispatchEvent(new Event(AdventureHotspotPolygon.CONNECTED));
					return;
				}
			}
			// Add point to points array
			trace("Added: " + lastMouse.toString());
			points.push(lastMouse);
			// Draw polygon with connector lines
			drawPolygon(false);
		}
		/**
		 * Draws the polygon using the global points vector.
		 * @param isFinal If false, draws anchors and line to current mouse position
		 */
		protected function drawPolygon(isFinal:Boolean):void
		{
			/* Clear out and reset the graphics */
			this.graphics.clear();
			anchorSprite.graphics.clear();
			this.graphics.moveTo(points[0].x, points[0].y);
			/* Prepare to draw the polygon */
			if(isFinal) this.graphics.beginFill(color, ALPHA_FILL);
			this.graphics.lineStyle(stroke, color, ALPHA_STROKE, true);
			/* Draw a line to each point */
			for each(var p:Point in points)
			{
				this.graphics.lineTo(p.x, p.y); // draw line to point
				/* Draw anchors so user knows where points are */
				if(!isFinal) {
					/* Draw anchor a different color if mouse is over it */
					if(mouseColissionCheck(p.x, p.y)) anchorSprite.graphics.beginFill(color, ALPHA_STROKE);
					else anchorSprite.graphics.beginFill(color, 0);
					/* Draw the anchor */
					anchorSprite.graphics.lineStyle(ANCHOR_STROKE_THICKNESS, color, 1, true, "normal", CapsStyle.NONE, JointStyle.MITER);
					anchorSprite.graphics.drawRect(p.x - ANCHOR_SIZE / 2, p.y - ANCHOR_SIZE / 2, ANCHOR_SIZE, ANCHOR_SIZE);
				}
			}
			if(!isFinal) {
				var tempColor:Color = new Color(color);
				tempColor.hsb = [(tempColor.hue + 30) % 360, tempColor.saturation ? 30 : 0, tempColor.saturation ? tempColor.brightness : (tempColor.brightness + 50) % 100];
				this.graphics.lineStyle(stroke, tempColor.value, ALPHA_STROKE, true);
				this.graphics.lineTo(lastMouse.x, lastMouse.y);
			}
			this.graphics.lineTo(points[0].x, points[0].y);
			this.graphics.endFill();
		}
		public override function finalize():void
		{
			trace("AdventureHotspotPolygon::finalize");
			trace(points.toString());
			super.finalize();
			var topLeft:Point = getTopLeft(points);
			var startPoint:Point = parent.globalToLocal(this.localToGlobal(new Point(topLeft.x, topLeft.y)));
			this.x = startPoint.x;
			this.y = startPoint.y;
			trace("x:" + this.x + " y:" + this.y);
			for(var i:int = 0; i < points.length; i++)
			{
				points[i].x -= topLeft.x;
				points[i].y -= topLeft.y;
			}
			drawPolygon(true);
			addInteraction();
		}
		public override function getPoints():Array
		{
			trace("AdventureHotspotPolygon::getPoints");
			var result:Array = new Array();
			for(var i:int = 0; i < points.length; i++) {
				result.push(targetImage.globalToLocal(this.parent.localToGlobal(new Point((this.x + points[i].x), (this.y + points[i].y)))));
			}
			return result;
		}
		public override function build(newPoints:Array):void
		{
			trace("AdventureHotspotPolygon::build");
			super.build(newPoints);
			var i:int;
			/* Find starting point (top-most y and left-most x from given array) */
			var topLeft:Point = getTopLeft(newPoints);
			trace(points.toString());
			var startPoint:Point = parent.globalToLocal(targetImage.localToGlobal(topLeft));
			this.x = startPoint.x;
			this.y = startPoint.y;
			/* Gather all points and convert to be relative to start x/y */
			points = new Vector.<Point>(newPoints.length);
			for(i = 0; i < newPoints.length; i++) {
				points[i] = this.globalToLocal(targetImage.localToGlobal(newPoints[i]));
				points[i].x;
				points[i].y;
			}
			drawPolygon(true);
			addInteraction();
		}
		public override function calculateArea():Number
		{
			var i:int;
			var area:Number = 0;
			// Find x and y axis to use for comparison in calculations
			var minX:Number = Number.MAX_VALUE;
			var minY:Number = Number.MAX_VALUE;
			for(i = 0; i < points.length; i++)
			{
				if(points[i].x < minX) minX = points[i].x;
				if(points[i].y < minY) minY = points[i].y;
			}
//			trace("minY: " + minY);
//			trace("minX: " + minX);
			// Calculate the area of the potentially irregular polygon
			for(i = 0; i < points.length; i++)
			{
				var p1:Point = points[i];
				var p2:Point;
				if(i == points.length - 1) p2 = points[0];
				else p2 = points[i+1];
//
//				trace(p1);
//				trace(p2);
				var distX:Number = (p2.x + p1.x) / 2 - minX;
				var distY:Number = (p2.y + p1.y) / 2 - minY;
				area += distX * distY;
			}
//			trace("area: " + area);
			return area;
		}
		protected function mouseColissionCheck(x:Number, y:Number):Boolean
		{
			return lastMouse.x >= x - ANCHOR_SIZE / 2 && lastMouse.x <= x + ANCHOR_SIZE / 2 && lastMouse.y >= y - ANCHOR_SIZE / 2 && lastMouse.y <= y + ANCHOR_SIZE;
		}
		private function getTopLeft(points:*):Point
		{
			var myX:Number = Number.MAX_VALUE;
			var myY:Number = Number.MAX_VALUE;
			for(var i:int = 0; i < points.length; i++)
			{
				if(points[i].x < myX) myX = points[i].x;
				if(points[i].y < myY) myY = points[i].y;
			}
			return new Point(myX, myY);
		}
		//----------------------------------
		//  Manage Resize Anchors
		//----------------------------------
		protected override function buildAnchors():void
		{
			super.buildAnchors();
			resizeAnchors = new Vector.<HotspotAnchor>(points.length);
			// Create the resize anchors
			for(var i:int = 0; i < resizeAnchors.length; i++)
			{
				var anchor:HotspotAnchor = resizeAnchors[i] = new HotspotAnchor(i, this.color);
				anchor.addEventListener(HotspotAnchor.DRAG, onAnchorDragged, false, 0, true);
				anchor.addEventListener(HotspotAnchor.DRAG_END, onAnchorDragEnd, false, 0, true);
			}
		}
		protected override function updateAnchorPositions():void
		{
			super.updateAnchorPositions();
			var radius:Number = HotspotAnchor.ANCHOR_SIZE / 2;
			for(var i:int = 0; i < points.length; i++)
			{
				resizeAnchors[i].x = points[i].x - radius;
				resizeAnchors[i].y = points[i].y - radius;
			}
		}
		protected override function onAnchorDragged(e:Event):void
		{
			super.onAnchorDragged(e);
			var anchor:HotspotAnchor = e.target as HotspotAnchor;
			var deltaX:Number;
			var deltaY:Number;
			deltaX = this.mouseX - points[anchor.id].x;
			deltaY = this.mouseY - points[anchor.id].y;
			points[anchor.id].x += deltaX;
			points[anchor.id].y += deltaY;
			updateAnchorPositions();
			redraw();
		}
	}
}