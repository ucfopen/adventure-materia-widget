package components.bubbles {
import flash.display.GradientType;
import flash.display.Sprite;
import flash.events.DataEvent;
import flash.events.Event;
import flash.events.FocusEvent;
import flash.events.MouseEvent;
import flash.geom.ColorTransform;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.utils.setTimeout;
import nm.draw.shapes.RectRound;
import nm.geom.Dimension;
public class ColorPicker extends Sprite
{
	public static const EVENT_COLOR_CHANGED:String = "color-changed";
	private static const TRANSFORM_HOVER:ColorTransform = new ColorTransform(.85, .85, .85);
	private static const TRANSFORM_NORMAL:ColorTransform = new ColorTransform(1, 1, 1);
	private static const TRANSFORM_PUSHED:ColorTransform = new ColorTransform(.75, .75, .75);
	private static const DEFAULT_COLORS:Vector.<Number> = Vector.<Number>([0xff0000, 0x00ff00, 0x0000ff]);
	private static const PADDING:Number = 5;
	public var colors:Vector.<Number>;
	private var _dim:Dimension;
	private var _colorSelected:int = 0;
	private var _corners:Number;
	private var _button:Sprite;
	private var _bar:ColorPickerBar;
	private var _drawPending:Boolean = false;
	private var _selectEvent:Event;
	//--------------------------------------------------------------------------
	//
	//  ColorPicker Constructor
	//
	//--------------------------------------------------------------------------
	public function ColorPicker(width:Number, height:Number, cornerRadius:Number = 0, colors:Vector.<Number> = null)
	{
		_dim = new Dimension(width, height);
		_corners = cornerRadius;
		if(colors == null) this.colors = DEFAULT_COLORS;
		else this.colors = colors;
		_button = new Sprite();
		this.addChild(_button);
		draw();
		_button.addEventListener(MouseEvent.CLICK, onSelect, false, 0, true);
		_button.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown, false, 0, true);
		_button.addEventListener(MouseEvent.MOUSE_UP, onMouseUp, false, 0, true);
		_button.addEventListener(MouseEvent.MOUSE_OVER, onMouseOver, false, 0, true);
		_button.addEventListener(MouseEvent.MOUSE_OUT, onMouseOut, false, 0, true);
		this.addEventListener(Event.ADDED_TO_STAGE, onAddedToStage, false, 0, true);
	}
	//--------------------------------------------------------------------------
	//
	//  Override Functions
	//
	//--------------------------------------------------------------------------
	public override function set width(val:Number):void
	{
		_dim = new Dimension(val, _dim.height);
		if(this.stage != null) draw();
		else _drawPending = true;
	}
	public override function set height(val:Number):void
	{
		_dim = new Dimension(_dim.width, val);
		if(this.stage != null) draw();
		else _drawPending = true;
	}
	//--------------------------------------------------------------------------
	//
	//  Member Functions
	//
	//--------------------------------------------------------------------------
	public function destroy():void
	{
		this.removeEventListener(MouseEvent.CLICK, onSelect);
		_button.removeEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
		_button.removeEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
		_button.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown, false, 0, true);
		_button.addEventListener(MouseEvent.MOUSE_UP, onMouseUp, false, 0, true);
		if(this.hasEventListener(Event.ADDED_TO_STAGE)) this.removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		if(stage.hasEventListener(MouseEvent.CLICK)) stage.removeEventListener(MouseEvent.CLICK, onStageClick);
		if(_bar != null)
		{
			if(_bar.parent != null) this.removeChild(_bar);
			if(_bar.hasEventListener(ColorPicker.EVENT_COLOR_CHANGED)) _bar.removeEventListener(ColorPicker.EVENT_COLOR_CHANGED, onColorSelected);
			_bar.destroy();
			_bar = null;
		}
	}
	public function setMainColor(color:Number):void
	{
		// Find the color and select it
		for(var i:int = 0; i < colors.length; i++)
		{
			if(color == colors[i])
			{
				_colorSelected = i;
				redraw();
				return;
			}
		}
		// if given color was not found, add it and select it
		colors.splice(0, 0, color);
		_colorSelected = 0;
		redraw();
	}
	public function draw():void
	{
		// Draw the background part of this color picker
		_button.graphics.clear();
		var matrix:Matrix = new Matrix();
		matrix.createGradientBox(_dim.width, _dim.height, (90 / 180) * Math.PI);
		RectRound.draw(_button, 0, 0, _dim.width, _dim.height, [_corners,_corners,_corners,_corners], {s:GradientType.LINEAR, c:[0xf1f1f1, 0xc1c1c1], a:[1,1], r:[0,0xff], m:matrix}, [1, 0xa1a1a1, 1, true]);
		redraw();
	}
	public function redraw():void
	{
		// Draw the filling part (chosen color) part of this picker
		_button.graphics.beginFill(colors[_colorSelected]);
		_button.graphics.drawRect(PADDING, PADDING, _dim.width - PADDING * 2, _dim.height - PADDING * 2);
		_button.graphics.endFill();
	}
	//----------------------------------
	//  Event Driven Functions
	//----------------------------------
	private var xxx:Event;
	protected function onSelect(e:Event):void
	{
		if(_bar != null && _bar.parent != null) return;
		if(_bar == null) _bar = new ColorPickerBar(colors);
		_bar.addEventListener(ColorPicker.EVENT_COLOR_CHANGED, onColorSelected, false, 0, true);
//		PopUpManager.addPopUp(_bar, this, false);
		this.addChild(_bar);
		var barPoint:Point = _bar.parent.globalToLocal(this.localToGlobal(new Point(_dim.width / 2, _dim.height)));
		_bar.x = barPoint.x - _bar.width / 2;
		_bar.y = barPoint.y;
		// Listen for Stage Click (but ignore current click event by saving it and comparing later)
		_selectEvent = e;
		stage.addEventListener(MouseEvent.CLICK, onStageClick, false, 0, true);
	}
	protected function onDeselect(e:Event = null):void
	{
		// Remove Listeners
		if(stage.hasEventListener(MouseEvent.CLICK)) stage.removeEventListener(MouseEvent.CLICK, onStageClick);
		_bar.removeEventListener(ColorPicker.EVENT_COLOR_CHANGED, onColorSelected);
		// Remove Color Picker Bar
		if(_bar != null && _bar.parent != null) _bar.parent.removeChild(_bar);
	}
	protected function onStageClick(e:Event):void
	{
		// if this stage click comes from onSelect(), ignore
		if(e == _selectEvent) return;
		onDeselect();
		return;
		if(_bar == null) onDeselect();
		if(!this.hitTestPoint(stage.mouseX, stage.mouseY, true)) onDeselect();
	}
	protected function onColorSelected(e:DataEvent):void
	{
		_colorSelected = int(e.data);
		redraw();
		// propagate the event to our parent
		dispatchEvent(new DataEvent(ColorPicker.EVENT_COLOR_CHANGED, false, false, String(colors[_colorSelected])));
	}
	protected function onAddedToStage(e:Event):void
	{
		this.removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		if(_drawPending) draw();
		_drawPending = false;
	}
	protected function onMouseDown(e:Event):void { _button.transform.colorTransform = TRANSFORM_PUSHED; }
	protected function onMouseUp(e:Event):void { _button.transform.colorTransform = TRANSFORM_HOVER; }
	protected function onMouseOver(e:Event):void { _button.transform.colorTransform = TRANSFORM_HOVER; }
	protected function onMouseOut(e:Event):void { _button.transform.colorTransform = TRANSFORM_NORMAL; }
}
}
import components.bubbles.ColorPicker;
import flash.display.GradientType;
import flash.display.Sprite;
import flash.events.DataEvent;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.filters.GlowFilter;
import flash.geom.Matrix;
import nm.draw.shapes.RectRound;
class ColorPickerBar extends Sprite
{
	private static const PICKER_DISTANCE:Number = 5;
	private static const SPACING:Number = 5;
	private static const PADDING:Number = 5;
	private var _colors:Vector.<Number>;
	private var _size:Number;
	private var _corners:Number;
	private var _pickers:Vector.<Sprite>;
	public function ColorPickerBar(colors:Vector.<Number>, squareSize:Number = 20, corners:Number = 3)
	{
		_colors = colors;
		_size = squareSize;
		_corners = corners;
		_pickers = new Vector.<Sprite>(_colors.length);
		draw();
	}
	public function destroy():void
	{
		for each(var picker:Sprite in _pickers)
		{
			picker.removeEventListener(MouseEvent.CLICK, onPickerSelect);
			picker.removeEventListener(MouseEvent.MOUSE_OVER, onPickerMouseOver);
			picker.removeEventListener(MouseEvent.MOUSE_OUT, onPickerMouseOut);
		}
	}
	public override function get width():Number
	{
		return _colors.length * (_size + SPACING) - SPACING + PADDING * 2;
	}
	public function draw():void
	{
		// Calculate width/height of picker bar
		var height:Number = _size;
		var width:Number = _colors.length * (_size + SPACING) - SPACING + PADDING * 2;
		// Start Fresh
		this.graphics.clear();
		// Draw the transparent background to satisfy hit test
		this.graphics.beginFill(0, 0);
		this.graphics.drawRect(0, 0, width, height + PICKER_DISTANCE);
		this.graphics.endFill();
		// Draw the background that will contain the pickers
		var matrix:Matrix = new Matrix();
		matrix.createGradientBox(width, height, (90 / 180) * Math.PI);
		RectRound.draw(this, 0, PICKER_DISTANCE, width, height + PADDING * 2, [_corners, _corners, _corners, _corners], {s:GradientType.LINEAR, c:[0xf1f1f1, 0xc1c1c1], a:[1,1], r:[0,0xff], m:matrix}, [1, 0xa1a1a1, 1, true]);
		// Create, draw and position individual pickers
		for(var i:int = 0; i < _colors.length; i++)
		{
			var picker:Sprite = _pickers[i] = new Sprite();
			var targX:Number = i * (_size + SPACING) + PADDING;
			picker.graphics.beginFill(_colors[i]);
			picker.graphics.lineStyle(1, 0);
			picker.graphics.drawRect(0, 0, _size, _size);
			picker.x = targX;
			picker.y = PICKER_DISTANCE + PADDING;
			picker.addEventListener(MouseEvent.CLICK, onPickerSelect, false, 1, true);
			picker.addEventListener(MouseEvent.MOUSE_OVER, onPickerMouseOver, false, 0, true);
			picker.addEventListener(MouseEvent.MOUSE_OUT, onPickerMouseOut, false, 0, true);
			addChild(picker);
		}
	}
	private function onPickerSelect(e:Event):void
	{
		var picker:Sprite = Sprite(e.target);
		for(var i:int = 0; i < _pickers.length; i++)
		{
			if(picker == _pickers[i]) { pickerSelect(i); return; }
		}
	}
	private function onPickerMouseOver(e:Event):void
	{
		e.target.filters = [new GlowFilter(0xffffff, 1, 8, 8, 3, 3)];
	}
	private function onPickerMouseOut(e:Event):void
	{
		e.target.filters = [];
	}
	private function pickerSelect(colorIndex:int):void
	{
		dispatchEvent(new DataEvent(ColorPicker.EVENT_COLOR_CHANGED, false, false, String(colorIndex)));
	}
}