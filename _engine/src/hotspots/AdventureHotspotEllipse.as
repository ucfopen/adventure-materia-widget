package hotspots {
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import AdventureOptions;
	public class AdventureHotspotEllipse extends AdventureDisplayHotspot
	{
		protected var lastMouse:Point = new Point(0, 0);
		public function AdventureHotspotEllipse(targetImage:DisplayObject, draggable:Boolean = true, visibility:int = AdventureOptions.VISIBILITY_ALWAYS)
		{
			super(targetImage, draggable, visibility);
			type = AdventureOptions.HOTSPOT_ELLIPSE;
			buildAnchors();
		}
		public override function redraw():void
		{
			super.redraw();
			drawEllipse();
		}
		public override function onMouseMoveCreate(e:MouseEvent):void
		{
			super.onMouseMoveCreate(e);
			// Get x and y position of mouse
			var mousePoint:Point = getMousePoint();
			// Make perfect circle if shift is held
			if(e.shiftKey)
			{
				mousePoint.x = mousePoint.y = Math.max(mousePoint.x, mousePoint.y);
			}
			// Set the second point for this ellilpse
			lastMouse = mousePoint;
			// Draw this ellipse
			redraw();
		}
		protected function drawEllipse():void {
			graphics.clear();
			graphics.lineStyle(stroke, color, ALPHA_STROKE, true);
			graphics.beginFill(color, ALPHA_FILL);
			graphics.drawEllipse(0, 0, lastMouse.x, lastMouse.y);
			graphics.endFill();
		}
		public override function finalize():void
		{
			super.finalize();
			if(lastMouse.x < 0)
			{
				this.x += lastMouse.x;
				lastMouse.x *= -1;
			}
			if(lastMouse.y < 0)
			{
				this.y += lastMouse.y;
				lastMouse.y *= -1;
			}
			drawEllipse();
			addInteraction();
		}
		public override function getPoints():Array
		{
			var startPoint:Point = targetImage.globalToLocal(this.parent.localToGlobal(new Point(this.x, this.y)));
			return [startPoint.x, startPoint.y, lastMouse.x / targetImage.scaleX, lastMouse.y / targetImage.scaleY];
		}
		public override function build(points:Array):void
		{
			super.build(points);
			var startPoint:Point = this.parent.globalToLocal(targetImage.localToGlobal(new Point(points[0], points[1])));
			this.x = startPoint.x;
			this.y = startPoint.y;
			lastMouse.x = points[2] * targetImage.scaleX;
			lastMouse.y = points[3] * targetImage.scaleY;
			drawEllipse();
			addInteraction();
		}
//		public override function changeTargetScale(oldScale:Number, newScale:Number):void
//		{
//			var modifier:Number = newScale / oldScale;
//			this.x *= modifier;
//			this.y *= modifier;
//			lastMouse.x *= modifier;
//			lastMouse.y *= modifier;
//		}
		public override function calculateArea():Number
		{
			var radius1:Number = lastMouse.x;
			var radius2:Number = lastMouse.y;
			return Math.PI * radius1 * radius2;
		}
		//----------------------------------
		//  Manage Resize Anchors
		//----------------------------------
		protected override function buildAnchors():void
		{
			super.buildAnchors();
			resizeAnchors = new Vector.<HotspotAnchor>(4);
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
			var radius:Number = HotspotAnchor.ANCHOR_SIZE / 2;
			resizeAnchors[0].x = lastMouse.x / 2 - radius;
			resizeAnchors[0].y = -radius;
			resizeAnchors[1].x = lastMouse.x - radius;
			resizeAnchors[1].y = lastMouse.y / 2 - radius;
			resizeAnchors[2].x = lastMouse.x / 2 - radius;
			resizeAnchors[2].y = lastMouse.y - radius;
			resizeAnchors[3].x = -radius;
			resizeAnchors[3].y = lastMouse.y / 2 - radius;
		}
		protected override function onAnchorDragged(e:Event):void
		{
			super.onAnchorDragged(e);
			var anchor:HotspotAnchor = e.target as HotspotAnchor;
			var deltaX:Number;
			var deltaY:Number;
			switch(anchor.id)
			{
				case 0:  // top anchor
					deltaY = this.mouseY;
					this.y += deltaY;
					lastMouse.y -= deltaY;
					break;
				case 1:  // right anchor
					deltaX = this.mouseX - lastMouse.x;
					lastMouse.x += deltaX;
					break;
				case 2:  // bottom anchor
					deltaY = this.mouseY - lastMouse.y;
					lastMouse.y += deltaY;
					break;
				case 3:  // left anchor
					deltaX = this.mouseX;
					this.x += deltaX;
					lastMouse.x -= deltaX;
					break;
			}
			updateAnchorPositions();
			redraw();
		}
	}
}