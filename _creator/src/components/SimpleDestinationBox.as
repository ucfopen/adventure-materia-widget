package components {
import components.bubbles.DestinationBubble;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.IEventDispatcher;
import flash.events.MouseEvent;
import flash.text.TextField;
import flash.text.TextFieldType;
import flash.text.TextFormat;
public class SimpleDestinationBox extends Sprite
{
	//--------------------------------------------------------------------------
	//
	//  Class constants
	//
	//--------------------------------------------------------------------------
	public static const DEFAULT_WIDTH:int = 50;
	public static const DEFATUL_HEIGHT:int = 24;
	//--------------------------------------------------------------------------
	//
	//  Instance Variables
	//
	//--------------------------------------------------------------------------
	public var bubble:DestinationBubble;
	private var _field:TextField;
	private var _dispatcher:IEventDispatcher;
	//--------------------------------------------------------------------------
	//
	//  Constructor
	//
	//--------------------------------------------------------------------------
	/**
	 * Simple destination box brings up a DestinationBubble on Click and keeps
	 * track of a destination to link to.
	 * @param bubbleListener The IEventDispatcher to be used to dispatch destination change events (defaults to this)
	 */
	public function SimpleDestinationBox(dispatcher:IEventDispatcher = null)
	{
		/* keep reference to dispatcher to use on click */
		_dispatcher = dispatcher ? dispatcher : this;
		/* initialize the input field */
		_field = new TextField;
		_field.type = TextFieldType.DYNAMIC;
		_field.background = true;
		_field.backgroundColor = 0xffffff;
		_field.border = true;
		_field.borderColor = 0xcccccc;
		_field.selectable = false;
		_field.width = DEFAULT_WIDTH;
		_field.height = DEFATUL_HEIGHT;
		_field.defaultTextFormat = new TextFormat(null, 16, null, true, null, null, null, null, "center");
		_field.addEventListener(MouseEvent.CLICK, onInputClick, false, 0, true);
		this.addChild(_field);
	}
	//--------------------------------------------------------------------------
	//
	//  Accessor Functions
	//
	//--------------------------------------------------------------------------
	public override function set width(val:Number):void { _field.width = val; }
	public override function set height(val:Number):void { _field.height = val; }
	public function get text():String { return _field.text; }
	public function set text(val:String):void { _field.text = val; }
	//--------------------------------------------------------------------------
	//
	//  Member Functions
	//
	//--------------------------------------------------------------------------
	private function onInputClick(e:Event):void
	{
		bubble = new DestinationBubble(_dispatcher);
		bubble.show(this);
	}
}
}