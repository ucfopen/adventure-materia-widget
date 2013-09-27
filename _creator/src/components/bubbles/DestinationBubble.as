package components.bubbles {
import flash.display.DisplayObject;
import flash.display.Sprite;
import flash.events.DataEvent;
import flash.events.Event;
import flash.events.IEventDispatcher;
import flash.events.MouseEvent;
import flash.geom.ColorTransform;
import flash.geom.Point;
import mx.controls.Button;
import mx.core.UIComponent;
import nm.ui.ToolTip;
public class DestinationBubble extends AdventureBubble
{
	public static const EVENT_DESTINATION_CHOICE:String = "destination-choice";
	public static const THIS_NODE:int = 0;
	public static const NEW_NODE:int = 1;
	public static const EXISTING_NODE:int = 2;
	private const WIDTH:Number = 130;
	private const HEIGHT:Number = 120;
	private const BUTTON_WIDTH:int = 115;
	private const BUTTON_HEIGHT:int = 23;
	private const SPACING:int = 5;
	private var button1:Button = new Button();
	private var button2:Button = new Button();
	private var button3:Button = new Button();
	private var _listener:IEventDispatcher;

	// The threshold by which tooltips will be occluded by the edge of the stage
	private const SCREEN_WIDTH_THRESHOLD:Number = 1085;
	private var _enableSelfNode:Boolean;

	private var _tooltipDirection:String = "left";

	public function DestinationBubble(buttonListener:IEventDispatcher, tooltipDirection:String = "left", enableSelfNode:Boolean = true)
	{
		super(WIDTH, HEIGHT, "Change Destination:");
		_listener = buttonListener ? buttonListener : this;
		var buttonX:Number = WIDTH / 2 - BUTTON_WIDTH / 2;
		var currY:Number = _startY;

		_tooltipDirection = tooltipDirection;

		button1.label = "This Node";
		button1.width = BUTTON_WIDTH;
		button1.height = BUTTON_HEIGHT;
		button1.x = buttonX;
		button1.y = currY;
		button1.setStyle("paddingLeft", 0);
		button1.setStyle("paddingRight", 0);
		button1.addEventListener(MouseEvent.CLICK, function a(e:Event):void {
			_listener.dispatchEvent(new DataEvent(EVENT_DESTINATION_CHOICE, false, false, String(THIS_NODE)));
			destroy();
		}, false, 0, true);
		currY += BUTTON_HEIGHT + SPACING;

		_enableSelfNode = enableSelfNode;

		this.addChild(button1);
		button2.label = "New Node";
		button2.width = BUTTON_WIDTH;
		button2.height = BUTTON_HEIGHT;
		button2.x = buttonX;
		button2.y = currY;
		button2.setStyle("paddingLeft", 0);
		button2.setStyle("paddingRight", 0);
		button2.addEventListener(MouseEvent.CLICK, function a(e:Event):void {
			_listener.dispatchEvent(new DataEvent(EVENT_DESTINATION_CHOICE, false, false, String(NEW_NODE)));
			destroy();
		}, false, 0, true);
		currY += BUTTON_HEIGHT + SPACING;

		this.addChild(button2);
		button3.label = "Existing Node ...";
		button3.width = BUTTON_WIDTH;
		button3.height = BUTTON_HEIGHT;
		button3.x = buttonX;
		button3.y = currY;
		button3.setStyle("paddingLeft", 0);
		button3.setStyle("paddingRight", 0);
		button3.addEventListener(MouseEvent.CLICK, function a(e:Event):void {
			_listener.dispatchEvent(new DataEvent(EVENT_DESTINATION_CHOICE, false, false, String(EXISTING_NODE)));
			destroy();
		}, false, 0, true);
		currY += BUTTON_HEIGHT + SPACING;

		this.addChild(button3);
	}
	public override function show(target:Sprite, direction:int = DIRECTION_UP, parent:DisplayObject = null):void
	{
		var pos:Point = target.localToGlobal(new Point(this.width, 0));

		if (pos.x < SCREEN_WIDTH_THRESHOLD) _tooltipDirection = "left";
		var tooltipOptions:Object = {direction:_tooltipDirection, showDelay:0, hideDelay:0, fadeTime:50}
		if(_enableSelfNode)
		{
			ToolTip.add(button1, "Choosing this path will bring the student back to this destination", tooltipOptions);
		}
		else
		{
			button1.enabled = false;
			button1.transform.colorTransform = new ColorTransform(.7, .7, .7, .8);
			ToolTip.add(button1, "Disabled because leading back here would cause an infinite cycle", tooltipOptions);
		}

		ToolTip.add(button2, "Choosing this path will bring the student to a new destination you will create", tooltipOptions);
		ToolTip.add(button3, "Choosing this path will bring the student to another (already existing) destination", tooltipOptions);

		super.show(target, direction, parent);
	}
	public override function destroy():void
	{
		super.destroy();
		// remove the tooltip to the self node if it was assigned (implicit if)
		ToolTip.remove(button1);
		ToolTip.remove(button2);
		ToolTip.remove(button3);
	}
}
}