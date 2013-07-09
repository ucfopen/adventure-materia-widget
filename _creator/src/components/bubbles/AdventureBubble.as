package components.bubbles {
import flash.display.DisplayObject;
import flash.display.Sprite;
import flash.display.Stage;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.filters.GlowFilter;
import flash.geom.Point;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFormat;
import mx.core.Application;
import mx.core.UIComponent;
public class AdventureBubble extends UIComponent
{
	public static const DIRECTION_UP:int = 0;
	public static const DIRECTION_DOWN:int = 1;
	public static const DIRECTION_LEFT:int = 2;
	public static const DIRECTION_RIGHT:int = 3;
	protected static const PADDING:int = 10;
	protected static const POINTER_HEIGHT:int = 12;
	public var initiator:DisplayObject;
	protected var _width:int = 130;
	protected var _height:int = 140;
	protected var _startY:Number = 0;
	protected var _stage:Stage;
	protected var _mouseWasInside:Boolean = false;
	protected var _label:String;
	protected var _direction:int = 0;
	private var _titleContainer:Sprite;
	public function AdventureBubble(width:Number, height:Number, label:String = null)
	{
		_width = width;
		_height = height;
		drawBubble();
		_label = label;
		if(label != null) drawLabel(label);
	}
	public function set direction(val:int):void { _direction = val; }
	public function get direction():int { return _direction; }
	public function show(target:Sprite, direction:int = DIRECTION_UP, parent:DisplayObject = null):void
	{
		_stage = target.stage;
		this.direction = direction;
		drawBubble();
		drawLabel(_label);
		if(parent == null) parent = DisplayObject(Application.application);
		initiator = parent;
		PopUpManager.addPopUp(this, parent, false, true);
		updatePosition(target);
		this.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDownInside, false, 0, true);
		this.addEventListener(MouseEvent.MOUSE_UP, onMouseUpInside, false, 0, true);
		callLater(function t():void {
			/* the remove listener is added in callLater because the click event
			   that triggers this function somehow propagates into this newly
			   added listner and closes the bubble prematurely
			*/
			_stage.addEventListener(MouseEvent.MOUSE_DOWN, onClickApplication, false, 0, true);
		});
	}
	public function updatePosition(target:Sprite):void
	{
		var targetPoint:Point;
		switch(direction)
		{
			case DIRECTION_DOWN:
				targetPoint = target.localToGlobal(new Point(target.width / 2, target.height));
				this.x = targetPoint.x - _width / 2;
				this.y = targetPoint.y + POINTER_HEIGHT;
				break;
			case DIRECTION_LEFT:
				targetPoint = target.localToGlobal(new Point(0, target.height / 2));
				this.x = targetPoint.x - _width - POINTER_HEIGHT;
				this.y = targetPoint.y - _height / 2;
				break;
			case DIRECTION_RIGHT:
				targetPoint = target.localToGlobal(new Point(target.width, target.height / 2));
				this.x = targetPoint.x + POINTER_HEIGHT;
				this.y = targetPoint.y - _height / 2;
				break;
			case DIRECTION_UP:
			default:
				targetPoint = target.localToGlobal(new Point(target.width / 2, 0));
				this.x = targetPoint.x - _width / 2;
				this.y = targetPoint.y - _height - POINTER_HEIGHT;
				break;
		}
	}
	public function destroy():void
	{
		trace("AdventureBubble:destroy");
		this.visible = false;
		PopUpManager.removePopUp(this);
		this.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDownInside);
		this.removeEventListener(MouseEvent.MOUSE_UP, onMouseUpInside);
		_stage.removeEventListener(MouseEvent.MOUSE_DOWN, onClickApplication);
	}
	protected function onMouseDownInside(e:Event):void
	{
		trace("AdventureBubble:onMouseDownInside [" + this.name + "]");
		_mouseWasInside = true;
	}
	protected function onMouseUpInside(e:Event):void
	{
		trace("AdventureBubble:onMouseDownInside [" + this.name + "]");
		_mouseWasInside = false;
	}
	protected function onClickApplication(e:Event):void
	{
		trace("AdventureBubble:onClickApplication [" + this.name + "]");
		/* Ignore Stage Click if it was propagated through clicking on bubble itself */
		if(_mouseWasInside)
		{
			_mouseWasInside = false;
			return;
		}
		/* Ignore click if it belonged to a "child" of this bubble */
		var target:DisplayObject = DisplayObject(e.target);
		while(target !=  null)
		{
			if(target == this) return;
			if(target is AdventureBubble) target = AdventureBubble(target).initiator;
			else target = target.parent;
		}
		/* Destroy this Bubble */
		destroy();
	}
	protected function drawBubble():void
	{
		var bgColor:Number = 0xeaeaea;
		var cr:int = 12;               // radius
		var pw:int = 14;               // pointer width
		var ph:int = POINTER_HEIGHT;   // pointer height
		var tw:int = _width;           // tooltip width
		var th:int = _height;          // tooltip height
		//Draw bubble with pointer oriented down
		this.graphics.clear();
		this.graphics.lineStyle();
		this.graphics.beginFill(bgColor, .95);
		this.graphics.moveTo(cr, 0);
		this.graphics.curveTo(0, 0, 0, cr);
		if(_direction == DIRECTION_RIGHT)              // draw tip LEFT
		{
			this.graphics.lineTo(0, th/2 - pw);
			this.graphics.lineTo(-ph, th/2);
			this.graphics.lineTo(0, th/2 + pw);
		}
		this.graphics.lineTo(0, th - cr);
		this.graphics.curveTo(0, th, cr, th);
		if(_direction == DIRECTION_UP)                 // draw tip DOWN
		{
			this.graphics.lineTo(tw/2 - pw, th);
			this.graphics.lineTo(tw/2, th + ph);
			this.graphics.lineTo(tw/2 + pw, th);
		}
		this.graphics.lineTo(tw - cr, th);
		this.graphics.curveTo(tw, th, tw, th - cr);
		if(_direction == DIRECTION_LEFT)               // draw tip RIGHT
		{
			this.graphics.lineTo(tw, th/2 + pw);
			this.graphics.lineTo(tw+ph, th/2);
			this.graphics.lineTo(tw, th/2 - pw);
		}
		this.graphics.lineTo(tw, cr);
		this.graphics.curveTo(tw, 0, tw - cr, 0);
		if(_direction == DIRECTION_DOWN)               // draw tip UP
		{
			this.graphics.lineTo(tw/2 + pw, 0);
			this.graphics.lineTo(tw/2, -ph);
			this.graphics.lineTo(tw/2 - pw, 0);
		}
		this.graphics.lineTo(cr, 0);
		this.graphics.endFill();
		this.filters = [new GlowFilter(0x0, .4, 4, 4)];
	}
	protected function drawLabel(title:String):void
	{
		if(_titleContainer != null) this.removeChild(_titleContainer);
		_titleContainer = new Sprite();
		var tf:TextField = new TextField();
		tf.selectable = false;
		tf.defaultTextFormat = new TextFormat("Arial", null, 0x0, true);
		tf.text = title;
		tf.autoSize = TextFieldAutoSize.LEFT;
		_titleContainer.addChild(tf);
		_titleContainer.x = PADDING;
		_titleContainer.y = PADDING;
		_titleContainer.graphics.lineStyle(1, 0xbbbbbb);
		_titleContainer.graphics.moveTo(0, tf.y + tf.height);
		_titleContainer.graphics.lineTo(_width - PADDING * 2, tf.y + tf.height);
		this.addChild(_titleContainer);
		_startY = _titleContainer.y + _titleContainer.height + 5;
	}
}
}