package components {
import flash.display.Sprite;
import flash.events.Event;
import flash.events.EventDispatcher;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import flash.filters.DropShadowFilter;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFormat;
import flash.ui.Keyboard;
public class NotificationBar extends Sprite
{
	//--------------------------------------------------------------------------
	//
	//  Class Constants
	//
	//--------------------------------------------------------------------------
	//----------------------------------
	//  Layout Constants
	//----------------------------------
	private static const WIDTH:Number = 470;
	private static const HEIGHT:Number = 36;
	private static const BUTTON_WIDTH:Number = 80;
	private static const BUTTON_HEIGHT:Number = 26;
	private static const CURVE_BG:Number = 5;
	private static const CURVE_BUTTON:Number = 3;
	private static const SPACING_H:Number = 10;
	//----------------------------------
	//  UI Constants
	//----------------------------------
	private static const FORMAT_TEXTFIELD:TextFormat = new TextFormat("Arial MT Bold", 14, 0x313130, true);
	private static const FILTERSET:Array = [new DropShadowFilter(2, 45, 0, .6)];
	//--------------------------------------------------------------------------
	//
	//  Instance Variables
	//
	//--------------------------------------------------------------------------
	private var _textField:TextField = new TextField();
	private var _button:ToolButton;
	private var _buttonCallback:Function;
	private var _keyListenerActive:Boolean;
	private var _stage:EventDispatcher;
	//--------------------------------------------------------------------------
	//
	//  Constructor
	//
	//--------------------------------------------------------------------------
	public function NotificationBar()
	{
		this.visible = false;
		draw();
		this.filters = FILTERSET;
		// initialize text field
		_textField.selectable = false;
		_textField.defaultTextFormat = FORMAT_TEXTFIELD;
		_textField.autoSize = TextFieldAutoSize.LEFT;
		addChild(_textField);
		// initialize button
		_button = new ToolButton(80, 26, null, [CURVE_BUTTON, CURVE_BUTTON, CURVE_BUTTON, CURVE_BUTTON], null, false, null, false);
		_button.addEventListener(MouseEvent.CLICK, onButtonClick, false, 0, false);
		_button.label = "Button";
		// hide the ugly focus rect that shows up on focus
		this.focusRect = false;
	}
	//--------------------------------------------------------------------------
	//
	//  Member Functions
	//
	//--------------------------------------------------------------------------
	public function destroy():void
	{
		if(_button != null) _button.removeEventListener(MouseEvent.CLICK, onButtonClick);
	}
	public function show(fieldText:String, buttonText:String = null, buttonCallback:Function = null):void
	{
		this.visible = true;
		_textField.htmlText = fieldText;
		_textField.x = WIDTH / 2 - _textField.width / 2;
		_textField.y = HEIGHT / 2 - _textField.height / 2;
		if(buttonText != null)
		{
			_button.label = buttonText;
			this.addChild(_button);
			_textField.x = (WIDTH - BUTTON_WIDTH - SPACING_H * 2) / 2 - _textField.width / 2;
			_button.x = this.width - BUTTON_WIDTH - SPACING_H;
			_buttonCallback = buttonCallback;
		}
	}
	public function hide():void
	{
		this.visible = false;
		if(_button.parent == this) this.removeChild(_button);
		_buttonCallback = null;
	}
	private function onButtonClick(e:Event):void
	{
		if(_buttonCallback != null) _buttonCallback.apply(this);
	}
	private function draw():void
	{
		this.graphics.beginFill(0xffe570);
		this.graphics.drawRoundRect(0, 0, WIDTH, HEIGHT, CURVE_BG);
	}
}
}