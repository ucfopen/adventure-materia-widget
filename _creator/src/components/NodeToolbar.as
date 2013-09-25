package components{
import flash.display.Sprite;
import flash.events.Event;
import flash.geom.Point;

import mx.core.Application;

import tree.DisplayNode;
import tree.Node;

public class NodeToolbar extends Sprite
{
	public static const BUTTON_WIDTH:Number = 48;
	public static const BUTTON_WIDTH_LONG:Number = 75;
	public static const BUTTON_HEIGHT:Number = 19;
	private static const BORDER_RADIUS:Number = 3;
	private static const EVENT_EDIT:String = "edit-node";
	private static const EVENT_COPY:String = "copy-node";
	private static const EVENT_DELETE:String = "delete-node";
	private static const CORNERS_LEFT:Array = [BORDER_RADIUS, 0, 0, BORDER_RADIUS];
	private static const CORNERS_RIGHT:Array = [0, BORDER_RADIUS, BORDER_RADIUS, 0];
	private static const CORNERS_NONE:Array = [0, 0, 0, 0];
	private static const CORNERS_BOTH:Array = [BORDER_RADIUS, BORDER_RADIUS, BORDER_RADIUS, BORDER_RADIUS];
	private static const NODE_SPACING:Number = 10;
	private var editButton:ToolButton;
	private var copyButton:ToolButton;
	private var deleteButton:ToolButton;
	public var _node:Node;
	public function NodeToolbar()
	{
		// Edit Button
		editButton = new ToolButton(BUTTON_WIDTH, BUTTON_HEIGHT, null, CORNERS_LEFT, new Event(EVENT_EDIT), false);
		editButton.label = "Edit";
		editButton.addEventListener(EVENT_EDIT, onEditNodeButton, false, 0, true);
		// Copy Button
		copyButton = new ToolButton(BUTTON_WIDTH, BUTTON_HEIGHT, null, CORNERS_NONE, new Event(EVENT_COPY), false);
		copyButton.label = "Copy";
		copyButton.addEventListener(EVENT_COPY, onCopyNodeButton, false, 0, true);
		// Delete Button
		deleteButton = new ToolButton(BUTTON_WIDTH, BUTTON_HEIGHT, null, CORNERS_RIGHT, new Event(EVENT_DELETE), false);
		deleteButton.label = "Delete";
		deleteButton.addEventListener(EVENT_DELETE, deleteNode, false, 0, true);
		addButtons();
		this.visible = false;
	}
	public function show(node:Node):void
	{
		// store reference to node
		_node = node;
		// hide labels that aren't necessary
		if(node.isEmpty && node.children.length == 0)
		{
			// Update Delete Button
			deleteButton.corners = CORNERS_BOTH;
			deleteButton.width = BUTTON_WIDTH_LONG;
			deleteButton.redraw();
			deleteButton.label = "Remove Path";
			deleteButton.x = 0;
			// Remove other buttons
			if(editButton.parent != null) removeChild(editButton);
			if(copyButton.parent != null) removeChild(copyButton);
		}
		else
		{
			// Update Delete Button
			deleteButton.corners = CORNERS_RIGHT;
			deleteButton.width = BUTTON_WIDTH;
			deleteButton.redraw();
			deleteButton.label = "Delete";
			// Add back all buttons
			addButtons()
			if(node.isShortcut || node.isEmpty)
			{
				if(copyButton.parent != null) removeChild(copyButton);
				deleteButton.x = editButton.x + BUTTON_WIDTH;
			}
		}
		// set position
		refreshPosition();
		// don't show for empty start node
		 if(node.parent == null && node.isEmpty) return;
		// show!
		this.visible = true;
	}
	public function refreshPosition():void
	{
		if(_node != null)
		{
			var point:Point = this.parent.globalToLocal(_node.displayNode.parent.localToGlobal(new Point(_node.displayNode.x, _node.displayNode.y)));
			this.x = point.x - this.width / 2;
			this.y = point.y + DisplayNode.radius + NODE_SPACING;
			
			// Move above node if pushed off the page
			var sh:int = Application.application.stage.stageHeight;
			if(y + height > sh)
			{
				y = point.y - DisplayNode.radius - NODE_SPACING - height;
			}
		}
	}
	public function addButtons():void
	{
		editButton.x = 0;
		copyButton.x = editButton.x + BUTTON_WIDTH;
		deleteButton.x = copyButton.x + BUTTON_WIDTH;
		addChild(editButton);
		addChild(copyButton);
		addChild(deleteButton);
	}
	public function hide():void
	{
		this.visible = false;
		_node = null;
	}
	private function onCopyNodeButton(e:Event):void
	{
		_node.displayNode.displayTree.beginCopyNode(_node);
		hide();
	}
	private function onEditNodeButton(e:Event):void
	{
		_node.displayNode.displayTree.selectNode(_node);
	}
	private function deleteNode(e:Event):void
	{
		_node.displayNode.displayTree.attemptDeleteNode(_node);
	}
}
}