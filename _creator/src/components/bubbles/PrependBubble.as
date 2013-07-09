package components.bubbles {
import flash.display.Bitmap;
import flash.display.CapsStyle;
import flash.display.JointStyle;
import flash.display.PixelSnapping;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.filters.DropShadowFilter;
import flash.geom.Point;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFormat;

import nm.ui.ToolTip;

import tree.DisplayNode;
import tree.Node;

public class PrependBubble extends Sprite
{
	public static const RADIUS:int = 20;
	public static const SPACING:int = 30;
	private static const FILTERSET_NORMAL:Array = [];
	private static const FILTERSET_HIGHLIGHT:Array = [new DropShadowFilter(2, 45, 0)];
	
	[Embed (source="../../assets/new_node.png")]
	public static const NEW_NODE:Class;
	
	
	public var targetNode:Node;
	private var _image:Sprite;
	public function PrependBubble()
	{
		_image = new Sprite();
		_image.mouseEnabled = false;
		
		var bitmap:Bitmap = new NEW_NODE;
		bitmap.pixelSnapping = PixelSnapping.NEVER;
		bitmap.smoothing = true;
		
		bitmap.x = -bitmap.width / 2;
		bitmap.y = -bitmap.height / 2;
		
		_image.addChild(bitmap);
		this.addChildAt(_image, 0);
//		this.graphics.beginFill(0xf0f0f0);
//		this.graphics.lineStyle(2, 0x666666);
//		this.graphics.drawCircle(0, 0, RADIUS);
//		this.graphics.endFill();
//		this.graphics.lineStyle(4, 0x888888, 1, false, "normal", CapsStyle.NONE, JointStyle.ROUND);
//		this.graphics.moveTo(0, -RADIUS);
//		this.graphics.lineTo(0, RADIUS);
//		this.graphics.moveTo(-RADIUS, 0);
//		this.graphics.lineTo(RADIUS, 0);
		this.visible = false;
		this.addEventListener(MouseEvent.MOUSE_OVER, onMouseOver, false, 0, true);
		this.addEventListener(MouseEvent.MOUSE_OUT, onMouseOut, false, 0, true);
	}
	public function destroy():void
	{
		this.removeEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
		this.removeEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
	}
	public function show(node:Node):void
	{
		targetNode = node;
		var target:DisplayNode = node.displayNode;
		var targetPoint:Point = parent.globalToLocal(target.localToGlobal(new Point(0, 0)));
		this.x = targetPoint.x;
		this.y = targetPoint.y - DisplayNode.radius - RADIUS - SPACING;
		var direction:String = this.x > this.parent.width / 2 ? "left" : "right";
		var targName:String = DisplayNode.idToLabel(node.id);
		var parentName:String = DisplayNode.idToLabel(node.parent.id);
		ToolTip.add(this, "Click to add a destination between \"" + parentName + "\" and \"" + targName + "\"", {direction:direction, yOffset:-RADIUS, xOffset:-RADIUS});
		this.visible = true
	}
	public function hide():void
	{
		ToolTip.remove(this);
		this.visible = false;
	}
	private function onMouseOver(e:Event):void
	{
		this.filters = FILTERSET_HIGHLIGHT
	}
	private function onMouseOut(e:Event):void
	{
		this.filters = FILTERSET_NORMAL;
	}
}
}