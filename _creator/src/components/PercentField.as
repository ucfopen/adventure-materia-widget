package components {
import flash.display.Stage;
import flash.events.Event;
import flash.events.FocusEvent;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import flash.text.TextField;
import flash.text.TextFieldType;
import flash.text.TextFormat;
import flash.ui.Keyboard;
import flash.utils.setTimeout;
/**
 * PercentField
 * @author Anthony Reyes
 * An extension of TextField that deals exclusively with percentages.
 * Input is restricted to numbers and the percent symbol. Percentage values can
 * be retrived as an integer using getValue() or set using setValue().
 * Automatically maintains the percentage symbol in the display.
 */
public class PercentField extends TextField
{
	//--------------------------------------------------------------------------
	//
	//  Constants
	//
	//--------------------------------------------------------------------------
	public static const EVENT_COMMIT:String = "value-commit";
	private static const TEXTFORMAT_DEFAULT:TextFormat = new TextFormat("Arial", 14, '0', true, null, null, null, null, "left");
	private static const COLOR_GRAY:Number = 0xc2c2c2;
	private static const COLOR_BLACK:Number = 0x0;
	//--------------------------------------------------------------------------
	//
	//  Instance Variables
	//
	//--------------------------------------------------------------------------
	public var minBoundary:int = 0;
	public var maxBoundary:int = 100;
	private var _stage:Stage;
	private var _inputFocused:Boolean = false;
	private var _reverting:Boolean = false;
	private var _revertText:String;
	private var _revertSelection:Array;
	private var _storedInputString:String = "";
	private var _storedInputIsValid:Boolean = false;
	private var _lastValidValue:int;
	//--------------------------------------------------------------------------
	//
	//  Constructor
	//
	//--------------------------------------------------------------------------
	/**
	 * Constructor
	 * @param minBoundary The smallest value this field should be allowed to hold
	 * @param maxBoundary The largest value this field should be allowed to hold
	 */
	public function PercentField(minBoundary:Number = 0, maxBoundary:Number = 100)
	{
		super();
		// field customization
		this.restrict = "0-9%";
		this.type = TextFieldType.INPUT;
		this.defaultTextFormat = TEXTFORMAT_DEFAULT;
		// listeners for interactivity
		this.addEventListener(MouseEvent.MOUSE_OVER, onInputOver, false, 0, true);
		this.addEventListener(MouseEvent.MOUSE_OUT, onInputOut, false, 0, true);
		this.addEventListener(FocusEvent.FOCUS_IN, onInputFocusIn, false, 0, true);
		this.addEventListener(FocusEvent.FOCUS_OUT, onInputFocusOut, false, 0, true);
		this.addEventListener(KeyboardEvent.KEY_DOWN, onInputKeyDown, false, 0, true);
		this.addEventListener(Event.ADDED_TO_STAGE, onAddedToStage, false, 0, true);
		this.addEventListener(Event.CHANGE, onChange, false, 0, true);
		// save boundary variables
		this.minBoundary = minBoundary;
		this.maxBoundary = maxBoundary;
		// set initial value
		setValue(0);

		setInputBorders(true, COLOR_GRAY);
	}
	//--------------------------------------------------------------------------
	//
	//  Instance Functions
	//
	//--------------------------------------------------------------------------
	/**
	 * Destroys all listeners and prepares for garbage collection
	 */
	public function destroy():void
	{
		/* remove listeners */
		this.removeEventListener(MouseEvent.MOUSE_OVER, onInputOver);
		this.removeEventListener(MouseEvent.MOUSE_OUT, onInputOut);
		this.removeEventListener(FocusEvent.FOCUS_IN, onInputFocusIn);
		this.removeEventListener(FocusEvent.FOCUS_OUT, onInputFocusOut);
		this.removeEventListener(KeyboardEvent.KEY_DOWN, onInputKeyDown);
		this.removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		this.removeEventListener(Event.CHANGE, onChange);
		if(_stage != null) _stage.removeEventListener(MouseEvent.CLICK, onStageClick);
	}
	/**
	 * Retrieves the value of the percent field as an integer
	 */
	public function getNumberValue():Number
	{
		return _lastValidValue;
	}
	/**
	 * Sets the percentage value of the field from an integer
	 */
	public function setValue(value:int):void
	{
		value = Math.max(minBoundary, Math.min(maxBoundary, value));
		_lastValidValue = value;
		_storedInputIsValid = false;
		this.text = value + "%";
	}
	/**
	 * Retrieves the integer value of the field as a string
	 */
	public function getStringValue():String
	{
		if(!_storedInputIsValid)
		{
			_storedInputString = this.text.match(new RegExp("[0-9]*"))[0];
			_storedInputIsValid = true;
		}
		return _storedInputString;
	}
	private function setInputBorders(visible:Boolean, color:Number = COLOR_GRAY):void
	{
		if(visible) this.borderColor = color;
		this.border = visible;
	}
	private function revertInput():void
	{
		_reverting = true;
		_revertText = this.text;
		_revertSelection = [this.selectionBeginIndex, this.selectionEndIndex];
	}
	//----------------------------------
	//  Listeners
	//----------------------------------
	private function onChange(e:Event):void
	{
		if(_reverting)
		{
			this.text = _revertText;
			_reverting = false;
			this.setSelection(_revertSelection[0], _revertSelection[1]);
		}
		_storedInputIsValid = false;
	}
	private function onAddedToStage(e:Event):void
	{
		if(_stage != null) return;
		_stage = this.stage;
		_stage.addEventListener(MouseEvent.CLICK, onStageClick, false, 0, true);
	}
	private function onInputOver(e:MouseEvent):void
	{
		if(_inputFocused) return;
	}
	private function onInputOut(e:MouseEvent):void
	{
		if(_inputFocused) return;
		setInputBorders(true)
	}
	private function onInputFocusIn(e:FocusEvent):void
	{
		if(_inputFocused) return;
		_inputFocused = true;
		setInputBorders(true, COLOR_BLACK);
		this.setSelection(0, this.text.length);
		setTimeout(this.setSelection, 100, 0, e.target.text.length);
	}
	private function onInputFocusOut(e:FocusEvent):void
	{
		/* set appearance to not-focused */
		_inputFocused = false;
		setInputBorders(true, COLOR_GRAY);
		/* prepare variables */
		var inputString:String = getStringValue();
		var inputValue:int = int(inputString);
		/* avoid empty field */
		if(inputString == null || !inputString.length)
		{
			this.text = _lastValidValue + "%";
			return;
		}
		/* maintain boundaries */
		inputValue = Math.max(minBoundary, Math.min(maxBoundary, inputValue));
		/* store result for later use */
		_lastValidValue = inputValue;
		/* update display and maintain percentage symbol */
		this.text = _lastValidValue + "%";
		dispatchEvent(new Event(EVENT_COMMIT));
	}
	private function onInputKeyDown(e:KeyboardEvent):void
	{
		if(_reverting) return;
		/* commit change and remove focus */
		if((e.keyCode == Keyboard.ENTER || e.keyCode == Keyboard.ESCAPE) && stage.focus == this)
		{
			stage.focus = null;
		}
		/* restrict input after the '%' symbol */
		var selectLength:int = this.selectionEndIndex - this.selectionBeginIndex;
		var tooLong:Boolean = this.text.length + 1 - selectLength > 4;
		var charTyped:String = String.fromCharCode(e.charCode);
		var charIsValid:Boolean = charTyped.match(new RegExp("[0-9]|%")) != null;
		var index:int = this.selectionBeginIndex;
		var afterPercent:Boolean = index > 0 && this.text.charAt(index - 1) == '%';
		if(charIsValid && (tooLong || afterPercent))
		{
			revertInput();
		}
	}
	private function onStageClick(e:MouseEvent):void
	{
		/* commit change and remove focus */
		if(e.target != this && _stage.focus == this)
		{
			_stage.focus = null;
		}
	}
}
}