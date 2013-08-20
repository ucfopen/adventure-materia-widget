package components
{
import tree.DisplayNode;
import tree.Node;
import flash.display.DisplayObjectContainer;
import flash.events.Event;
import flash.events.EventDispatcher;
import flash.events.MouseEvent;
import flash.geom.Point;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFormat;
public class ImportDisplayNode extends DisplayNode
{
	//--------------------------------------------------------------------------
	//
	//  Constants
	//
	//--------------------------------------------------------------------------
	public static const EVENT_DRAG_BEGIN:String = "nodeDragBegin";
	public static const EVENT_DRAG_END:String = "nodeDragEnd";
	//--------------------------------------------------------------------------
	//
	//  Instance Variables
	//
	//--------------------------------------------------------------------------
	private var _dragging:Boolean = false;
	private var _originalParent:DisplayObjectContainer;
	private var _originalPosition:Point;
	private var _mouseUpDispatcher:EventDispatcher;
	private var _mouseMoveDispatcher:EventDispatcher;
	private var _mouseDragDiff:Point;
	//--------------------------------------------------------------------------
	//
	//  Constructor
	//
	//--------------------------------------------------------------------------
	public function ImportDisplayNode(node:Node)
	{
		super(null);
		this.node = node;
		node.parent = node;
		_drawCentered = false;
//		showWarningFlag(false);
//		showNewFlag(false);
		this.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown, false, 0, true);
	}
	//--------------------------------------------------------------------------
	//
	//  Inherited Functions
	//
	//--------------------------------------------------------------------------
	public override function drawShape(shapeRadius:Number = NaN):void
	{
		super.drawShape(DisplayNode.RADIUS_STANDARD);
	}
	public override function redraw():void
	{
		// set up graphics
		graphics.clear();
		// adjust the label text
		_label.text = node.data.type.toUpperCase();
		_label.visible = true;
		// draw the shape & filters for this node
		drawShape();
		updateFilters();
	}
	public override function updateFilters():void
	{
		if(this.parent == null) return;
		if(!_highlighted)
		{
			this.filters = FILTERSET_NORMAL;
		}
		else
		{
			this.filters = FILTERSET_EMPTY_HIGHLIGHT;
		}
	}
	//----------------------------------
	//  Inherited Event Handlers
	//----------------------------------
	protected override function onMouseOver(e:Event):void
	{
		_highlighted = true;
		updateFilters();
	}
	protected override function onMouseOut(e:Event):void
	{
		_highlighted = false;
		updateFilters();
	}
	//--------------------------------------------------------------------------
	//
	//  Instance Functions
	//
	//--------------------------------------------------------------------------
	private function setDragMode(val:Boolean):void
	{
		if(_dragging == val) return;
		/* start dragging this node and attach to mouse movement */
		if(val)
		{
			_dragging = true;
			/* Let listeners know we are dragging */
			dispatchEvent(new Event(EVENT_DRAG_BEGIN, true));
			/* store original position */
			_originalParent = this.parent;
			_originalPosition = new Point(this.x, this.y);
			/* add to stage so we can follow mouse movement */
			var newPosition:Point = stage.globalToLocal(this.parent.localToGlobal(_originalPosition));
			this.x = newPosition.x;
			this.y = newPosition.y;
			stage.addChild(this);
			/* Disable mouse interactivity to allow mouse actions to go through (for dropping) */
			this.mouseEnabled = false;
			_image.mouseEnabled = false;
			onMouseOut(null);
			/* listen for mouse movement to update position */
			_mouseDragDiff = new Point(stage.mouseX - this.x, stage.mouseY - this.y);
			_mouseMoveDispatcher = stage;
			_mouseMoveDispatcher.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove, false, 0, true);
		}
		/* stop dragging this node and return to original position */
		else
		{
			/* stop dragging */
			_dragging = false;
			_mouseMoveDispatcher.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			/* Undo disabling of mouse events */
			this.mouseEnabled = true;
			_image.mouseEnabled = true;
			/* restore original parent and position */
			this.x = _originalPosition.x;
			this.y = _originalPosition.y;
			_originalParent.addChild(this);
			/* Let listeners know we are no longer dragging */
			dispatchEvent(new Event(EVENT_DRAG_END, true));
		}
	}
	//----------------------------------
	//  Event Handlers
	//----------------------------------
	private function onMouseDown(e:MouseEvent):void
	{
		/* remove stage mouse-up listener if it still exists */
		if(_mouseUpDispatcher != null)
		{
			_mouseUpDispatcher.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			_mouseUpDispatcher = null;
		}
		/* only proceed if we have access to the stage */
		if(stage != null)
		{
			setDragMode(true);
			_mouseUpDispatcher = stage;
			_mouseUpDispatcher.addEventListener(MouseEvent.MOUSE_UP, onMouseUp, false, 0, true);
		}
	}
	private function onMouseUp(e:MouseEvent):void
	{
		setDragMode(false);
		_mouseUpDispatcher.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
		_mouseUpDispatcher = null;
	}
	private function onMouseMove(e:MouseEvent):void
	{
		this.x = e.stageX - _mouseDragDiff.x;
		this.y = e.stageY - _mouseDragDiff.y;
	}
}
}