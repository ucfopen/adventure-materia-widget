package components
{
	import flash.utils.Timer;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;

	import components.bubbles.ColorPicker;
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.DataEvent;
	import flash.events.Event;
	import flash.geom.Point;
	import hotspots.AdventureDisplayHotspot;
	import mx.controls.Image;
	import mx.core.Application;
	import mx.core.UIComponent;
	import nm.draw.shapes.RectRound;
	public class HotspotToolbar extends UIComponent
	{
		import nm.ui.ToolTip;
		public static const EVENT_HOTSPOT_CREATE:String = "Create-Hotspot";
		public static const EVENT_HOTSPOT_SHOW:String = "Show-Hotspot";
		public static const EVENT_HOTSPOT_HIDE:String = "Hide-Hotspot";
		public static const EVENT_HOTSPOT_SETTINGS:String = "Show-Settings";
		public static const PADDING:int = 5;
		private static const BUTTON_WIDTH:Number = 30;
		private static const BUTTON_HEIGHT:Number = 30;
		public var settingsButton:ToolButton;
		public var colorPicker:ColorPicker;
		protected static const MIN_WIDTH:int = 230;
		protected static const BORDER_RADIUS:int = 4;
//		protected static const PICKER_COLORS:Vector.<Number> = Vector.<Number>([AdventureDisplayHotspot.DEFAULT_COLOR_FILL, 0xcc6666, 0x66cc66, 0x6666cc, 0xcccc66, 0xcc66cc, 0x66cccc, 0xffffff, 0x000000]);
		protected static const PICKER_COLORS:Vector.<Number> = Vector.<Number>([AdventureDisplayHotspot.DEFAULT_COLOR_FILL, 0xff4444, 0x44ff44, 0x4444ff, 0xffff44, 0xff44ff, 0x44ffff,	0xffffff, 0x000000]);
		protected var _width:int = 130;
		protected var _height:int = 42;
		protected var _titleContainer:Sprite;
		protected var _buttons:Vector.<ToolButton>;
		protected var _highlightRect:Sprite;
		protected static const TOOLTIP_OPTIONS:Object = { direction:"up", htmlText:true };
		protected static const TOOLTIP_STYLE:Object = { htmlText:true };
		public function HotspotToolbar()
		{
			_buttons = new Vector.<ToolButton>;
			createButtons();
		}
		public function show(target:Image):void
		{
			// Color Pallette available at creators.timeline2.layouts.TimelineColorPopup
			_width = Math.max(MIN_WIDTH, target.content.width);
			redrawToolbar();
			var targetPoint:Point = target.localToGlobal(new Point(target.content.width / 2, 0));
			PopUpManager.addPopUp(this, DisplayObject(Application.application), false);
			this.x = targetPoint.x - _width / 2;
			this.y = targetPoint.y - _height - 5;
		}
		public function unPushButtons():void
		{
			for each(var button:ToolButton in _buttons)
			{
				if(button.toggleLinked) button.unPush();
			}
		}
		public function destroy():void
		{
			colorPicker.destroy();
			PopUpManager.removePopUp(this);
			for each(var button:ToolButton in _buttons)
			{
				button.destroy();
			}
			_buttons = null;
		}
		protected function onMouseDownInside(e:Event):void
		{
			e.stopPropagation();
		}
		protected function createButtons():void
		{
			// Create Rect Button
			_buttons[0] = new ToolButton(BUTTON_WIDTH, BUTTON_HEIGHT,
				ToolButton.ICON_RECT,
				[BORDER_RADIUS, 0, 0, BORDER_RADIUS],
				new DataEvent(EVENT_HOTSPOT_CREATE,true, false, String(AdventureOptions.HOTSPOT_RECT)));
			ToolTip.add(_buttons[0], "Draw a Rectangular Hotspot", TOOLTIP_OPTIONS, TOOLTIP_STYLE);
			addChild(_buttons[0]);
			// Create Ellipse Button
			_buttons[1] = new ToolButton(BUTTON_WIDTH, BUTTON_HEIGHT,
				ToolButton.ICON_ELLIPSE,
				[0, 0, 0, 0],
				new DataEvent(EVENT_HOTSPOT_CREATE,true, false, String(AdventureOptions.HOTSPOT_ELLIPSE)));
			ToolTip.add(_buttons[1], "Draw an Elliptical Hotspot", TOOLTIP_OPTIONS, TOOLTIP_STYLE);
			addChild(_buttons[1]);
			// Create Polygon Button
			_buttons[2] = new ToolButton(BUTTON_WIDTH, BUTTON_HEIGHT,
				ToolButton.ICON_POLYGON,
				[0, BORDER_RADIUS, BORDER_RADIUS,0],
				new DataEvent(EVENT_HOTSPOT_CREATE,true, false, String(AdventureOptions.HOTSPOT_POLYGON)));
			ToolTip.add(_buttons[2], "Draw a Polygonal Hotspot", TOOLTIP_OPTIONS, TOOLTIP_STYLE);
			addChild(_buttons[2]);
			// Create the Color Picker
			colorPicker = new ColorPicker(BUTTON_WIDTH, BUTTON_HEIGHT, BORDER_RADIUS, PICKER_COLORS);
			ToolTip.add(colorPicker, "Change the Hotspot Color", TOOLTIP_OPTIONS, TOOLTIP_STYLE);
			addChild(colorPicker);
			// Eye Button
			_buttons[3] = new ToolButton(BUTTON_WIDTH, BUTTON_HEIGHT,
				ToolButton.ICON_EYE,
				[BORDER_RADIUS, BORDER_RADIUS, BORDER_RADIUS, BORDER_RADIUS],
				new Event(EVENT_HOTSPOT_SHOW, true), true, new Event(EVENT_HOTSPOT_HIDE, true), false);
//			addChild(_buttons[3]);
			// Set Eye Icon as Pushed By Default
			_buttons[3].push();
			// Settings Button
			_buttons[4] = new ToolButton(BUTTON_WIDTH, BUTTON_HEIGHT,
				ToolButton.ICON_KOG,
				[BORDER_RADIUS, BORDER_RADIUS, BORDER_RADIUS, BORDER_RADIUS],
				new Event(EVENT_HOTSPOT_SETTINGS, true), false);
			ToolTip.add(_buttons[4], "Hotspot Settings", TOOLTIP_OPTIONS, TOOLTIP_STYLE);
			addChild(_buttons[4]);
			// Draw the highlighting rectangle
			_highlightRect = new Sprite();
			_highlightRect.graphics.lineStyle(4, 0x00ff00, .9);
			_highlightRect.graphics.drawRect(0, 0, BUTTON_WIDTH * 3 + PADDING * 2, _height);
			_highlightRect.visible = false;
			addChild(_highlightRect);
			// Initialize listeners
			this.addEventListener(ToolButton.EVENT_LINKED_PUSHED, onLinkedButtonPushed, false, 0, true);
			colorPicker.addEventListener(ColorPicker.EVENT_COLOR_CHANGED, onColorSelected, false, 0, true);

			colorPicker.addEventListener(MouseEvent.CLICK, hackColorTooltip, false, 0, true);

			// Set up any button references
			settingsButton = _buttons[4];
		}

		private function hackColorTooltip(e:MouseEvent):void
		{
			colorPicker.removeEventListener(MouseEvent.CLICK, hackColorTooltip, false)
			ToolTip.remove(colorPicker, false)
		}

		public function highlightCreateButtons():void
		{
			_highlightRect.visible = true;
		}
		public function unHighlightCreateButtons():void
		{
			_highlightRect.visible = false;
		}
		protected function redrawToolbar():void
		{
			this.graphics.clear();
			RectRound.draw(this, 0, 0, _width, _height, [10, 10, 0, 0], 0xf0f0f0, [1, 0xd1d1d1, 1, true]);
			var currentX:int = PADDING;
			/* Position the rectangle hotspot button */
			_buttons[0].x = currentX;
			currentX += BUTTON_WIDTH;
			/* Position the ellipse hotspot button */
			_buttons[1].x = currentX;
			currentX += BUTTON_WIDTH;
			/* Position the polygon hotspot button */
			_buttons[2].x = currentX;
			currentX += BUTTON_WIDTH;
			/* Prepare to place right-side buttons */
			currentX = _width - PADDING - BUTTON_WIDTH;
			 /* Position the settings button */
			_buttons[4].x = currentX;
			currentX -= BUTTON_WIDTH + PADDING;
			/* Position the view hotspots button */
//			_buttons[3].x = currentX;
//			currentX -= BUTTON_WIDTH + PADDING;
			/* Position the color picker*/
			colorPicker.x = currentX;
			colorPicker.y = _height / 2 - colorPicker.height / 2;
			currentX -= BUTTON_WIDTH + PADDING;
		}
		private function onLinkedButtonPushed(e:Event):void
		{
			unPushButtons()
		}
		private function onColorSelected(e:DataEvent):void
		{
			ToolTip.add(colorPicker, "Change the Hotspot Color", TOOLTIP_OPTIONS, TOOLTIP_STYLE)

			// Propagate this event so the HotspotImage gets it
			dispatchEvent(e)

			//TODO: FIND A WAY OF FIXING THIS THAT DOES NOT INVOLVE A TIMER
			var dammitAnthony:Timer = new Timer(100, 1)
			dammitAnthony.addEventListener(TimerEvent.TIMER, function():void {
				colorPicker.addEventListener(MouseEvent.CLICK, hackColorTooltip, false, 0, true)
			}, false, 0, true)
			dammitAnthony.start()
		}
	}
}