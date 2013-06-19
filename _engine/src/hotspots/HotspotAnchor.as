package hotspots {
import flash.display.Sprite;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.geom.ColorTransform;
import nm.draw.Color;
public class HotspotAnchor extends Sprite
{
	public static const DRAG:String = "anchor-dragged";
	public static const DRAG_END:String = "anchor-drag-stopped";
	public static const ANCHOR_SIZE:int = 6;
	/**
	 * The array position this anchor holds in an array, used as identifier
	 */
	public var id:int;
	private var _color:uint;
	private var _adjustedColor:uint;
	private var _dragging:Boolean = false;
	public function HotspotAnchor(id:int, color:uint)
	{
		super();
		this.id = id;
		setColor(color);
		draw();
		this.addEventListener(MouseEvent.MOUSE_OVER, onMouseOver, false, 0, true);
		this.addEventListener(MouseEvent.MOUSE_OUT, onMouseOut, false, 0, true);
		this.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown, false, 0, true);
		this.addEventListener(MouseEvent.CLICK, onMouseClick, false, 0, true);
	}
	public function destroy():void
	{
		this.removeEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
		this.removeEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
		this.removeEventListener(MouseEvent.CLICK, onMouseClick);
		if(_dragging)
		{
			this.removeEventListener(MouseEvent.MOUSE_MOVE, onDrag);
			this.removeEventListener(MouseEvent.MOUSE_UP, onDrag);
		}
	}
	public function get color():uint { return _color; }
	public function set color(val:uint):void
	{
		setColor(val);
		draw();
	}
	private function setColor(val:uint):void
	{
		_color = val;
		var temp:Color = new Color(val);
		temp.hsb = [(temp.hue + 30) % 360, temp.saturation ? 50 : 0, temp.saturation ? temp.brightness / 2 : (temp.brightness + 50) % 100];
		_adjustedColor = temp.value;
	}
	private function draw(filled:Boolean = false):void
	{
		this.graphics.clear();
		this.graphics.beginFill(_color, filled?1:0);
		this.graphics.lineStyle(2, _adjustedColor);
		this.graphics.drawRect(0, 0, ANCHOR_SIZE, ANCHOR_SIZE);
	}
	private function onMouseOver(e:Event):void
	{
		draw(true);
	}
	private function onMouseOut(e:Event):void
	{
		draw(false);
	}
	private function onMouseDown(e:Event):void
	{
		e.stopPropagation();
		if(_dragging) return;
		startDragging();
	}
	private function onDrag(e:Event):void
	{
		this.dispatchEvent(new Event(DRAG));
	}
	private function onMouseUp(e:Event):void
	{
		e.stopPropagation();
		stopDragging();
	}
	private function onMouseClick(e:Event):void
	{
		e.stopPropagation();
	}
	private function startDragging():void
	{
		_dragging = true;
		stage.addEventListener(MouseEvent.MOUSE_MOVE, onDrag, false, 0, true);
		stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp, false, 0, true);
	}
	private function stopDragging():void
	{
		if(!_dragging) return;
		stage.removeEventListener(MouseEvent.MOUSE_MOVE, onDrag);
		stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
		_dragging = false;
		dispatchEvent(new Event(DRAG_END));
	}
}
}