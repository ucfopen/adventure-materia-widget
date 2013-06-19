package components
{
	import components.HotspotToolbar;
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.display.GradientType;
	import flash.display.PixelSnapping;
	import flash.display.Sprite;
	import flash.events.DataEvent;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import mx.controls.Image;
	import mx.core.Application;
	import mx.core.UIComponent;
	import nm.draw.shapes.RectRound;
	import AdventureOptions;
	import nm.geom.Dimension;
	public class ToolButton extends Sprite
	{
		public static const EVENT_LINKED_PUSHED:String = "unpush-linked";
		//--------------------------------------------------------------------------
		//
		//  Embedded Icons for Toolbar Buttons
		//
		//--------------------------------------------------------------------------
		[Embed (source="../assets/toolbar/rect.png")]
		public static const ICON_RECT:Class;
		[Embed (source="../assets/toolbar/ellipse.png")]
		public static const ICON_ELLIPSE:Class;
		[Embed (source="../assets/toolbar/polygon.png")]
		public static const ICON_POLYGON:Class;
		[Embed (source="../assets/toolbar/eye.png")]
		public static const ICON_EYE:Class;
		[Embed (source="../assets/toolbar/kog.png")]
		public static const ICON_KOG:Class;
		//--------------------------------------------------------------------------
		//
		//  Static Rules for Buttons
		//
		//--------------------------------------------------------------------------
		private static const TRANSFORM_PUSHED:ColorTransform = new ColorTransform(.75, .75, .75);
		private static const TRANSFORM_HOVER:ColorTransform = new ColorTransform(.85, .85, .85);
		private static const TRANSFORM_NORMAL:ColorTransform = new ColorTransform(1, 1, 1);
		private static const TEXT_FORMAT:TextFormat = new TextFormat("Arial", 10, 0x5d5d5d, true, null, null, null, null, "center");
		//--------------------------------------------------------------------------
		//
		//  Instance Variables
		//
		//--------------------------------------------------------------------------
		public var corners:Array;
		public var toggleLinked:Boolean;
		private var _clickEvent:Event;
		private var _unClickEvent:Event;
		private var _pushed:Boolean = false;
		private var _toggle:Boolean;
		private var _label:TextField;
		private var _dim:Dimension;
		//--------------------------------------------------------------------------
		//
		//  ToolButton Constructor
		//
		//--------------------------------------------------------------------------
		/**
		 * Creates a new ToolButton - A button used in toolbars that can have
		 * rounded corners and can toggle if set as a toggle button.
		 *
		 * @param toolbar A reference to the toolbar the button is held in
		 * @param corners An array radiuses for the corners of these buttons [top-left,top-right,bottom-right,bottom-left]
		 * @param clickEvent A custom event to be dispatched when the button is pressed
		 * @param toggles Whether or not this is a toggle button
		 * @param clickEvent A custom event to be dispatched when the button is unpressed (only in toggle mode)
		 * @param toggleLinked Whether or not this button's toggle state is mutually exclusive
		 */
		public function ToolButton(width:Number, height:Number, iconClass:Class, corners:Array, clickEvent:Event, toggles:Boolean = true, unClickEvent:Event = null, toggleLinked:Boolean = true)
		{
			_dim = new Dimension(width, height);
			_toggle = toggles;
			this.toggleLinked = _toggle && toggleLinked;
			this.corners = corners;
			redraw();
			this.y = HotspotToolbar.PADDING;
			this.addEventListener(MouseEvent.MOUSE_OVER, onMouseOver, false, 0, false);
			this.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown, false, 0, false);
			this.addEventListener(MouseEvent.MOUSE_OUT, onMouseOut, false, 0, false);
			if(clickEvent)
			{
				_clickEvent = clickEvent;
				_unClickEvent = unClickEvent ? unClickEvent : _clickEvent;
				this.addEventListener(MouseEvent.CLICK, onMouseClick, false, 0, false);
			}
			if(iconClass != null)
			{
				var icon:Bitmap = new iconClass();
				icon.x = (_dim.width - icon.width) / 2;
				icon.y = (_dim.height - icon.height) / 2;
				this.addChild(icon);
			}
		}
		//--------------------------------------------------------------------------
		//
		//  Override Functions
		//
		//--------------------------------------------------------------------------
		public override function set width(val:Number):void
		{
			_dim = new Dimension(val, _dim.height);
		}
		public override function set height(val:Number):void
		{
			_dim = new Dimension(_dim.width, val);
		}
		//--------------------------------------------------------------------------
		//
		//  Member Functions
		//
		//--------------------------------------------------------------------------
		public function redraw():void
		{
			this.graphics.clear();
			var matrix:Matrix = new Matrix();
			matrix.createGradientBox(_dim.width, _dim.height, (90 / 180) * Math.PI);
			RectRound.draw(this, 0, 0, _dim.width, _dim.height, corners, {s:GradientType.LINEAR, c:[0xf1f1f1, 0xc1c1c1], a:[1,1], r:[0,0xff], m:matrix}, [1, 0xa1a1a1, 1, true]);
		}
		public function destroy():void
		{
			this.removeEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
			this.removeEventListener(MouseEvent.MOUSE_OVER, onMouseOut);
			if(_clickEvent) this.removeEventListener(MouseEvent.CLICK, onMouseClick);
		}
		public function push():void
		{
			_pushed = true;
			resetState();
		}
		public function unPush():void
		{
			_pushed = false;
			resetState();
		}
		public function set label(val:String):void
		{
			if(_label != null) removeChild(_label);
			_label = new TextField();
			_label.width = this.width;
			_label.selectable = false;
			_label.defaultTextFormat = TEXT_FORMAT;
			_label.autoSize = TextFieldAutoSize.CENTER;
			_label.text = val;
			_label.y = _dim.height / 2 - _label.height / 2;
			addChild(_label);
		}
		private function onMouseDown(e:Event = null):void
		{
			this.transform.colorTransform = TRANSFORM_PUSHED;
		}
		private function onMouseOver(e:Event = null):void
		{
			this.transform.colorTransform = TRANSFORM_HOVER;
		}
		private function onMouseOut(e:Event = null):void
		{
			if(!_pushed) this.transform.colorTransform = TRANSFORM_NORMAL;
			else applyPushedTransform();
		}
		private function applyPushedTransform():void
		{
			this.transform.colorTransform = TRANSFORM_PUSHED;
		}
		private function resetState():void
		{
			if(_pushed) applyPushedTransform();
			else onMouseOut();
		}
		private function unPushButtons():void
		{
			dispatchEvent(new Event(EVENT_LINKED_PUSHED, true));
		}
		private function onMouseClick(e:Event):void
		{
			var oldState:Boolean = _pushed;                    // remember current pushed state
			if(toggleLinked) unPushButtons();                  // if any other buttons are pushed, unpush
			if(_pushed) dispatchEvent(_unClickEvent); // dispatch the custom event for unclicking
			else dispatchEvent(_clickEvent);          // dispatch the custom event for clicking
			if(_toggle) _pushed = !oldState;                   // toggle pushed state
			else transform.colorTransform = TRANSFORM_HOVER    // if not toggle mode, swich to normal hover appearance
			resetState();                                      // update filters according to new state
		}
	}
}