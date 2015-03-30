package hotspots {
import flash.display.DisplayObject;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.geom.ColorTransform;
import flash.geom.Point;
import AdventureOptions;
public class AdventureHotspotRect extends AdventureDisplayHotspot
{
	protected var lastMouse:Point = new Point(0, 0);
	public function AdventureHotspotRect(targetImage:DisplayObject, draggable:Boolean = true, visibility:int = AdventureOptions.VISIBILITY_ALWAYS)
	{
		super(targetImage, draggable, visibility);
		type = AdventureOptions.HOTSPOT_RECT;
		buildAnchors();
	}
	public override function destroy():void
	{
		for each(var anchor:HotspotAnchor in resizeAnchors)
		{
			anchor.removeEventListener(HotspotAnchor.DRAG, onAnchorDragged);
			anchor.removeEventListener(HotspotAnchor.DRAG_END, onAnchorDragged);
			anchor.destroy();
		}
	}
	public override function redraw():void
	{
		super.redraw();
		drawRect();
	}
	public override function onMouseMoveCreate(e:MouseEvent):void
	{
		// Get x and y position of mouse
		var mousePoint:Point = getMousePoint();
		// Make perfect square if shift is held
		if(e.shiftKey)
		{
			mousePoint.x = mousePoint.y = Math.max(mousePoint.x, mousePoint.y);
		}
		// Set the second point for this rectangle
		lastMouse = mousePoint;
		// Draw this rectangle
		redraw();
	}
	protected function drawRect():void {
		graphics.clear();
		graphics.lineStyle(stroke, color, ALPHA_STROKE, true);
		graphics.beginFill(color, ALPHA_FILL);
		graphics.drawRect(0, 0, lastMouse.x, lastMouse.y);
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
		drawRect();
		addInteraction();
	}
	/**
	 * Returns the coordinates used to construct this rectangle (only needs
	 * top-left and bottom-right coordinates).
	 * @return Array [0]/[1] is top-left point; [2]/[3] is bottom-right point;
	 */
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
		drawRect();
		addInteraction();
	}
	public override function calculateArea():Number
	{
		var height:Number = lastMouse.y;
		var width:Number = lastMouse.x;
		return width * height;
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
		super.updateAnchorPositions();
		var radius:Number = HotspotAnchor.ANCHOR_SIZE / 2;
		resizeAnchors[0].x = -radius;
		resizeAnchors[0].y = -radius;
		resizeAnchors[1].x = lastMouse.x - radius;
		resizeAnchors[1].y = -radius;
		resizeAnchors[2].x = lastMouse.x - radius;
		resizeAnchors[2].y = lastMouse.y - radius;
		resizeAnchors[3].x = -radius;
		resizeAnchors[3].y = lastMouse.y - radius;
	}
	protected override function onAnchorDragged(e:Event):void
	{
		super.onAnchorDragged(e);
		var anchor:HotspotAnchor = e.target as HotspotAnchor;
		var deltaX:Number;
		var deltaY:Number;
		switch(anchor.id)
		{
			case 0:  // top-left anchor
				deltaX = this.mouseX;
				deltaY = this.mouseY;
				this.x += deltaX;
				this.y += deltaY;
				lastMouse.x -= deltaX;
				lastMouse.y -= deltaY;
				break;
			case 1:  // top-right anchor
				deltaX = this.mouseX - lastMouse.x;
				deltaY = this.mouseY;
				lastMouse.x += deltaX;
				this.y += deltaY;
				lastMouse.y -= deltaY;
				break;
			case 2:  // bottom-right anchor
				deltaX = this.mouseX - lastMouse.x;
				deltaY = this.mouseY - lastMouse.y;
				lastMouse.x += deltaX;
				lastMouse.y += deltaY;
				break;
			case 3:  // bottom-left anchor
				deltaX = this.mouseX;
				deltaY = this.mouseY - lastMouse.y;
				this.x += deltaX;
				lastMouse.x -= deltaX;
				lastMouse.y += deltaY;
				break;
		}
		updateAnchorPositions();
		redraw();
	}
}
}