package tree {
import Creator;

import adt.Queue;
import adt.Stack;

import components.NodeToolbar;
import components.NotificationBar;
import components.bubbles.NodeBubble;
import components.bubbles.PrependBubble;
import components.bubbles.TracerBubble;

import flash.display.CapsStyle;
import flash.display.DisplayObject;
import flash.display.DisplayObjectContainer;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.EventDispatcher;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFormat;
import flash.ui.Keyboard;

import materia.Dialog;
import materia.questionStorage.Question;
import materia.questionStorage.QuestionGroup;

import mx.core.Container;
import mx.core.UIComponent;
import mx.events.FlexEvent;

import HelperBubbleManager;

import nm.ui.Button;
public class DisplayTree extends Sprite
{
	//--------------------------------------------------------------------------
	//
	//  Class constants
	//
	//--------------------------------------------------------------------------
	private static const PADDING_V:Number = 10;
	private static const PADDING_H:Number = 25;
	private static const MAX_CHILDREN:int = 80;
	private static const EDGE_CURVE:int = 10;
	private static const LEVEL_HEIGHT_MAX:int = 150;
	private static const LEVEL_HEIGHT_MIN:int = 90;
	private static const LEAF_WIDTH_MAX:int = 150;
	private static const LEAF_WIDTH_MIN:int = 30;
	//--------------------------------------------------------------------------
	//
	//  Instance Variables
	//
	//--------------------------------------------------------------------------
	//----------------------------------
	//  Tree Modes
	//----------------------------------
	public var linkEditMode:Boolean = false;
	public var nodeCopyMode:Boolean = false;
	public var nodeImportMode:Boolean = false;
	public var copyTarget:Node;
	public var linkTarget:Node;
	private var _editModeCallback:Function;
	private var _linkTargetPoint:Point;
	//----------------------------------
	//  Creation/Deletion Variables
	//----------------------------------
	private var _deleteTarget:Node;
	private var _treeBackup:Node;
	private var _recoveredIdsBackup:Vector.<int>;
	private var _idIncrement:int = 0;
	private var _linkIdIncrement:int = Creator.LINK_ID_START;
	private var _recoveredIds:Vector.<int> = new Vector.<int>;
	private var _pendingDeletions:Vector.<Sprite> = new Vector.<Sprite>;
	private var _drawComplete:Boolean = false;
	private var _lastAddedNode:DisplayNode;
	//----------------------------------
	//  External References
	//----------------------------------
	private var _stage:EventDispatcher;
	private var _creator:Creator;
	private var _container:Container;
	private var _displayArea:UIComponent;
	private var _overlay:DisplayObjectContainer;
	private var _nodesMarkedAsNew:Array;
	private var helperManager:HelperBubbleManager;
	//----------------------------------
	//  UI Components
	//----------------------------------
	private var _bg:Sprite;
	private var _lineLayer:Sprite;
	private var _branchHighlightLayer:Sprite;
	private var _tree:Sprite;
	private var _root:DisplayNode;
	private var _debugButton:Button;
	private var _debugField:TextField;
	private var _prependBubble:PrependBubble;
	private var _nodeBubble:NodeBubble;
	private var _tracerBubble:TracerBubble;
	private var _hoverHotspot:Sprite;
	private var _lastNodeHovered:DisplayNode;
	private var _nodeToolbar:NodeToolbar;
	private var _notificationBar:NotificationBar;
	//----------------------------------
	//  Layout Variables
	//----------------------------------
	private var _levelHeight:Number;
	private var _levelWidth:Number;
	private var _currentTweens:int = 0;
	//----------------------------------
	//  Uncategorized
	//----------------------------------
	//--------------------------------------------------------------------------
	//
	//  Constructor
	//
	//--------------------------------------------------------------------------
	public function DisplayTree(creatorInterface:Creator)
	{
		// Store useful references
		_creator = creatorInterface;
		_overlay = _creator.flashOverlay;
		helperManager = _creator.helperManager;
		// Create container sprites
		_bg = new Sprite();
		_lineLayer = new Sprite();
		_tree = new Sprite();
		_tree.x = PADDING_H;
		_branchHighlightLayer = new Sprite();
		// Listen for added to stage
		addEventListener(Event.ADDED_TO_STAGE, onAddedToStage, false, 0, true);
		// Add Children
		addChild(_bg);
		addChild(_tree);
		_tree.addChild(_branchHighlightLayer);
		_tree.addChild(_lineLayer);
	}
	//--------------------------------------------------------------------------
	//
	//  Accessor Functions
	//
	//--------------------------------------------------------------------------
	// public function get scoreStyle():int { return _creator.scoreStyle; }
	//--------------------------------------------------------------------------
	//
	//  Member Functions
	//
	//--------------------------------------------------------------------------
	public function destroy():void
	{
		_prependBubble.destroy();
		nodeMouseOut();
		if(_notificationBar != null) _notificationBar.destroy();
	}
	/**
	 * Adds a node to the display tree. Doubly links the nodes through parent/child references,
	 * and sets the given question data to the new node.
	 * Does not affect the question/answer data of the parent node.
	 * This operation will trigger the destruction of the backup tree if it exists.
	 */
	public function addNode(parentNode:Node, data:Question = null, isLink:Boolean = false):DisplayNode
	{
		var result:DisplayNode;
		if(parentNode == null)
		{
			result = _root = createDisplayNode(new Node(getNextId()));
		}
		else
		{
			result = DisplayNode(parentNode.displayNode.addChildNode(createDisplayNode(new Node(getNextId()))));
			_tree.setChildIndex(parentNode.displayNode, _tree.numChildren - 1);
		}
		// Set Data
		if(data == null) result.node.resetData();
		else result.node.data = data;
		// If we had a backup, destroy it
		destroyBackupTree();
		
		return result;
	}
	public function resetHotspotNode(target:Node):void
	{
		_deleteTarget = target;
		var questionText:String = target.data.questions[0].text;
		var layout:int = target.data.options.layout;
		deleteTargetedNode(target.children.length >= 1);
		target.type = AdventureOptions.TYPE_HOTSPOT;
		target.data.questions[0].text = questionText;
		target.data.addOption("layout", layout);
	}
	public function attemptDeleteNode(target:Node, saveBackup:Boolean = true):Boolean
	{
		nodeMouseOut();
		/* Refuse removal of Start Node */
		if(target.isRoot && target.isEmpty)
		{
			Dialog.show(Dialog.OK, "Cannot Remove Start", "The start destination cannot be removed.");
			return false;
		}
		/* Warn on deletion of subtree */
		if(target.children.length > 1)
		{
			_deleteTarget = target;
			Dialog.show(Dialog.YESNO, "Deleting Destination", "Deleting this destination will result in all of the destinations it leads to being deleted. Are you sure?", deleteTargetedNode, [saveBackup]);
		}
		/* Delete anything else without prompt */
		else
		{
			_deleteTarget = target;
			return deleteTargetedNode(saveBackup);
		}
		return true;
	}
	/**
	 * Called by the attemptDeleteNode function
	 * Deletes a node previously deemed as acceptable for deletion
	 */
	private function deleteTargetedNode(saveBackup:Boolean = true):Boolean
	{
		var i:int;
		var deletedIds:Array = new Array();
		var deleteTargetParent:Node = _deleteTarget.parent;
		/* Add IDs to recovered ID array and delete graphic */
		var stack:Stack = new Stack();
		if(_deleteTarget.isEmpty && _deleteTarget.children.length == 0)
		{
			var errorTitle:String;
			var errorMessage:String;
			// Create a backup of current tree
			if(saveBackup) createBackupTree();
			stack.push(_deleteTarget);
			if(!_deleteTarget.isRoot) { _deleteTarget.parent.removeChild(_deleteTarget); } // Dereference by removing from parent
		}
		else
		{
			// Create a backup of current tree
			if(saveBackup) createBackupTree();
			/* If targeted node only has one child, just delete and replace with child */
			if(!_deleteTarget.isRoot && _deleteTarget.children.length == 1)
			{
				_deleteTarget.parent.replaceChild(_deleteTarget, _deleteTarget.children[0]);
				_deleteTarget.children.pop();
				stack.push(_deleteTarget);
			}
			else
			{
				// add of all its children to the stack
				while(_deleteTarget.children.length)
				{
					stack.push(_deleteTarget.children[0]);
					_deleteTarget.removeChild(_deleteTarget.children[0]);
				}
			}
		}
		/* Recover deleted nodes from display; recover their IDs */
		var current:Node;
		while(!stack.isEmpty())
		{
			// find current node
			current = Node(stack.pop());
			// add of all its children to the stack
			while(current.children.length)
			{
				stack.push(current.children.pop());
			}
			// recover its id
			_recoveredIds.push(current.id);
			// keep track of deleted ids
			deletedIds.push(current.id);
			// remove it from display
			_pendingDeletions.push(current.displayNode);
		}
		// set node as empty
		emptyNode(_deleteTarget);
		// Sort the recovered ID array (ascending so smallest is at end)
		sortRecoveredIds();
		/* Fix Any Shortcuts We Broke by Doing This */
		fixBrokenShortcuts(deletedIds);
		/* Redraw the tree */
		redraw();
		/* Dereference delete target */
		_deleteTarget = null;
		// Check parent for validation errors
		if(deleteTargetParent != null) deleteTargetParent.checkForErrors();
		redraw();
		return true;
	}
	public function createBackupTree():void
	{
		// Make the backup
		_treeBackup = _root.node.clone();
		_recoveredIdsBackup = _recoveredIds.slice();
		// Show the Delete Notification and Undo Button
		var msg:String = "A node was deleted <font color='#777777'>(Escape to hide)</font>";
		if(_deleteTarget != null && !_deleteTarget.isShortcut) msg = "Node \"" + DisplayNode.idToLabel(_deleteTarget.id) + "\" was deleted <font color='#777777'>(Escape to hide)</font>";
		else if(_deleteTarget != null && _deleteTarget.isShortcut) msg = "Shortcut to \"" + DisplayNode.idToLabel(_deleteTarget.shortcut) + "\" was deleted <font color='#777777'>(Escape to hide)</font>";
		_notificationBar.show(msg, "Undo", restoreBackupTree);
	}
	public function restoreBackupTree():void
	{
		var i:int;
		var current:Node;
		if(!_treeBackup)
		{
			_notificationBar.hide();
			return;
		}
		var displayPoints:Vector.<Point> = new Vector.<Point>(_root.node.numLeafs);
		var stack:Stack = new Stack();
		for(i = 0; i < _root.node.children.length; i++)
		{
			stack.push(_root.node.children[i]);
		}
		// remove old display nodes
		while(!stack.isEmpty())
		{
			current = Node(stack.pop());
			// save display point
			if(current.id > displayPoints.length) displayPoints.length = current.id + 1;
			displayPoints[current.id] = new Point(current.displayNode.x, current.displayNode.y);
			_pendingDeletions.push(current.displayNode);
			for(i = 0; i < current.children.length; i++)
			{
				stack.push(current.children[i]);
			}
		}
		_root.node = _treeBackup;
		_treeBackup.displayNode = _root;
		for(i = 0; i < _root.node.children.length; i++)
		{
			stack.push(_root.node.children[i]);
		}
		// create new display nodes
		while(!stack.isEmpty())
		{
			current = Node(stack.pop());
			var newNode:DisplayNode = createDisplayNode(current);
			newNode.settled = true; // assume they aren't new (branch lines will be drawn during tween)
			// find its x/y position
			if(current.id < displayPoints.length && displayPoints[current.id] != null)
			{
				newNode.x = displayPoints[current.id].x;
				newNode.y = displayPoints[current.id].y;
			}
			else
			{
				newNode.x = newNode.node.parent.displayNode.x;
				newNode.y = newNode.node.parent.displayNode.y;
			}
			// check for validation errors
			current.checkForErrors();
			// add its children to the stack
			for(i = 0; i < current.children.length; i++)
			{
				stack.push(current.children[i]);
			}
		}
		// restore old recoveredIds array
		_recoveredIds = _recoveredIdsBackup.slice();
		redraw();
		destroyBackupTree();
	}
	private function destroyBackupTree():void
	{
		_treeBackup = null;
		if(_notificationBar)
		{
			_notificationBar.hide();
		}
	}
	private function fixBrokenShortcuts(idsToCheck:Array):void
	{
		/* Find Broken Shortcuts */
		var i:int;
		var treeStack:Stack = new Stack();
		var brokenShortcuts:Queue = new Queue();
		treeStack.push(_root.node);
		var current:Node;
		while(!treeStack.isEmpty())
		{
			// find current node
			current = Node(treeStack.pop());
			// add all of its children to the stack
			for(i = 0; i < current.children.length; i++)
			{
				treeStack.push(current.children[i]);
			}
			// check against all IDs in given array
			for(i = 0; i < idsToCheck.length; i++)
			{
				// add to list of broken links
				if(current.shortcut == idsToCheck[i])
				{
					brokenShortcuts.enqueue(current);
				}
			}
		}
		/* Convert to Empty Nodes */
		while(!brokenShortcuts.isEmpty())
		{
			current = Node(brokenShortcuts.dequeue());
			current.id = getNextId();
			emptyNode(current, true);
		}
	}
	private function emptyNode(node:Node, force:Boolean = false):Node
	{
		if(node.isEmpty && !force) return null;
		if(node.isShortcut) node.id = getNextId();
		node.shortcut = -1;
		node.resetData();
		node.isNew = true;
		node.type = AdventureOptions.TYPE_NONE;
		if(!node.isRoot)
		{
			var childIndex:int = node.parent.getChildIndex(node);
			if(node.parent.data.answers.length > childIndex)
			{
				node.parent.data.answers[childIndex].options.link = node.id; // in case it was a shortcut
			}
		}
		return node;
	}
	private function showLinkError():void
	{
		Dialog.show(Dialog.OK, "Cannot Change Path", "This destination leads to other paths and cannot be changed. Please delete all of the paths it leads to first.", redraw);
	}
	/**
	 * Begin editing the link node with the given id.
	 *
	 * @param id The id of the link node to edit
	 * @param callback The function to call back after the new link is chosen
	 */
	public function editLink(id:int, callback:Function):void
	{
		// store link target
		linkTarget = getNodeFromId(id);
		// abort if link target has children
		if(linkTarget.children.length)
		{
			showLinkError();
			linkEditMode = false;
			callback.apply(this);
			_editModeCallback = null;
			return;
		}
		// turn on link edit mode
		linkEditMode = true;
		_editModeCallback = callback;
		// show instructions to user
		_notificationBar.show("Click on a destination to link to", "Cancel", cancelCurrentMode);
		// redraw the nodes to represent link edit mode
		redraw();
		this.addEventListener(Event.ENTER_FRAME, updateEditLine, false, 0, true);
		updateLinkTargetPoint();
		// bring link line layer and link target to top
		_tree.addChild(_lineLayer);
		_tree.addChild(linkTarget.displayNode);
	}
	public function beginCopyNode(node:Node):void
	{
		var i:int;
		// Check if an empty node exists in the tree
		var emptyNodeExists:Boolean = false;
		var stack:Stack = new Stack();
		stack.push(_root.node);
		while(!stack.isEmpty())
		{
			var current:Node = Node(stack.pop());
			if(current.isEmpty)
			{
				emptyNodeExists = true;
				break;
			}
			for(i = 0; i < current.children.length; i++)
			{
				stack.push(current.children[i]);
			}
		}
		// Abort if there are no empty nodes to copy to
		if(!emptyNodeExists)
		{
			Dialog.show(Dialog.OK, "No Empty Destination to Copy To", "A destination can only be copied to an empty destination. Please create an empty destination first.");
			return;
		}
		// Start Node Copy Mode
		nodeCopyMode = true;
		copyTarget = node;
		// Redraw nodes to reflect node copy mode
		redraw();
		// Show copy mode instruction to user
		_notificationBar.show("Click on an empty destination to copy to", "Cancel", cancelCurrentMode);
	}
	public function copyNode(targ:Node, dest:DisplayNode):void
	{
		var i:int;
		// clone original node
		var copy:Node = targ.clone();
		copy.id = dest.node.id;
		nodeCopyMode = false;
		// Copy target node into dest
		dest.node.parent.replaceChild(dest.node, copy);
		dest.node = copy;
		copy.displayNode = dest;
		// remove "new" flag on destination node
		dest.markedAsNew = false;
		// add children of clone to stack to be processed
		var stack:Stack = new Stack();
		for(i = 0; i < copy.children.length; i++)
		{
			assignNewId(copy, i);
			stack.push(copy.children[i]);
		}
		// Create New Display Nodes
		var current:Node;
		while(!stack.isEmpty())
		{
			current = Node(stack.pop());
			createDisplayNode(current);
			for(i = 0; i < current.children.length; i++)
			{
				// Assign new id
				assignNewId(current, i);
				stack.push(current.children[i]);
			}
		}
		// Hide copy mode instruction
		_notificationBar.hide();
		// Show those nodes!
		redraw();
	}
	public function beginImportMode():void
	{
		nodeImportMode = true;
		redraw();
	}
	public function attemptImport(data:Question, succeessCallback:Function):void
	{
		if(_hoverHotspot.parent != null && _lastNodeHovered.node.isEmpty)
		{
			_lastNodeHovered.node.data = data;
			_lastNodeHovered.node.imported = true;
			selectNode(_lastNodeHovered.node);
			succeessCallback();
		}
		nodeImportMode = false;
		redraw();
	}
	public function redraw():void
	{
		//----------------------------------
		//  Manage Veritical Tree Overflow
		//----------------------------------
		if(_root != null)
		{
			// prepare variables (for cleaner code)
			var triggerScrollDown:Boolean = false;
			var treeHeight:int = _root.node.treeHeight;
			var newHeight:Number;
			// determine new height for the display tree
			if(treeHeight * LEVEL_HEIGHT_MAX < _container.height) newHeight = treeHeight * LEVEL_HEIGHT_MAX;
			else if(treeHeight * LEVEL_HEIGHT_MIN < _container.height) newHeight = _container.height;
			else newHeight = _root.node.treeHeight * LEVEL_HEIGHT_MIN;
			// determine if we need to scroll down to keep focus on newly added nodes
			var lastWasInBetween:Boolean = _lastAddedNode && _lastAddedNode.node.children.length > 0;
			if(newHeight >= _container.height && newHeight > _displayArea.height && !lastWasInBetween) triggerScrollDown = true;
			_displayArea.height = newHeight;
			// vertically center the display tree if no overflow
			if(_displayArea.height >= _container.height) _displayArea.setStyle("verticalCenter", null);
			else _displayArea.setStyle("verticalCenter", 0);
			// scroll down if newly added node is below visibility
			if(triggerScrollDown)_container.addEventListener(FlexEvent.UPDATE_COMPLETE, autoScrollDown, false, 0, true);
		}
		//----------------------------------
		//  Manage Horizontal Tree Overflow
		//----------------------------------
		if(_root != null)
		{
			// prepare variables (for cleaner code)
			var numLeafs:int = _root.node.numLeafs;
			var newWidth:Number;
			// determine new width for the display tree
			if(numLeafs * LEAF_WIDTH_MAX < _container.width) newWidth = numLeafs * LEAF_WIDTH_MAX;
			else if(numLeafs * LEAF_WIDTH_MIN < _container.width) newWidth = _container.width;
			else newWidth = _root.node.numLeafs * LEAF_WIDTH_MIN;
			// determine if horizontal scroll-bars and centering are necessary
			if(newWidth > _container.width)
			{
				_creator.scrollCanvas.horizontalScrollPolicy = "on";
				_displayArea.setStyle("horizontalCenter", null);
			}
			else
			{
				_creator.scrollCanvas.horizontalScrollPolicy = "off";
				_displayArea.setStyle("horizontalCenter", 0);
			}
			// update display
			_displayArea.width = newWidth;
			_creator.scrollCanvas.invalidateDisplayList();
		}
		//----------------------------------
		//  Redraw Components
		//----------------------------------
		// draw the nodes
		DisplayNode.resetStandardRadii();
		organizeTree();
		// draw line layer (for showing connector lines)
		_lineLayer.graphics.clear();
		_lineLayer.graphics.drawRect(0, 0, _displayArea.width, _displayArea.height);
		// remove any display nodes that need to be deleted
		while(_pendingDeletions.length) _tree.removeChild(_pendingDeletions.pop());
		// adjust debug button
		_debugButton.x = PADDING_H;
		_debugButton.y = _overlay.height - _debugButton.height - PADDING_V;
	}
	private function autoScrollDown(e:Event):void
	{
		_container.removeEventListener(FlexEvent.UPDATE_COMPLETE, autoScrollDown);
		_container.verticalScrollPosition = _container.maxVerticalScrollPosition;
	}
	public function clearTree():void
	{
		for(var i:int = 0; i < _tree.numChildren; i++)
		{
			if(_tree.getChildAt(i) is DisplayNode)
			{
				_tree.removeChildAt(i);
				i--;
			}
		}
		_root = null;
		_idIncrement = 0;
		_recoveredIds = new Vector.<int>;
	}
	/**
	 * Returns the AdventureNode with the given ID or null if such a node doesn't exist
	 */
	public function getNodeFromId(id:int):Node
	{
		if(_root == null) return null;
		var stack:Stack = new Stack();
		stack.push(_root.node);
		var i:int;
		while(!stack.isEmpty())
		{
			var current:Node = Node(stack.pop());
			if(current.id == id) return current;
			for(i = 0; i < current.children.length; i++)
			{
				stack.push(current.children[i]);
			}
		}
		return null;
	}
	public function getNextId():int
	{
		var result:int;
		if(_recoveredIds.length == 0) result = _idIncrement++;
		else result = _recoveredIds.pop();
		return result;
	}
	/**
	 * Used only by the copyNode function. Assigns a new id to the child of the
	 * given parent at the given targetIndex. Assumes the current id for the
	 * target node is reduntant and does not release old id.
	 */
	public function assignNewId(parent:Node, targetIndex:int):void
	{
		// Assign new id
		var newId:int;
		if(!parent.children[targetIndex].isShortcut)
		{
			newId = getNextId();
			parent.children[targetIndex].id = newId;
			if(parent.data.answers != null) parent.data.answers[targetIndex].options.link = newId;
		}
		else
		{
			newId = _linkIdIncrement++;
			parent.children[targetIndex].id = newId;
		}
	}
	public function generateQGroup(name:String):QuestionGroup
	{
		if(_root == null) return null;
		var i:int, j:int;
		// Create empty question group
		var qGroup:QuestionGroup = new QuestionGroup();
		qGroup.name = name;
		// qGroup.options.scoreStyle = _creator.scoreStyle;
		// Create array to hold questions from tree
		var nodes:Vector.<Node> = new Vector.<Node>();
		// Initialize stack
		var stack:Stack = new Stack();
		stack.push(_root.node)
		/* Add nodes from the tree to an array */
		var current:Node;
		while(!stack.isEmpty())
		{
			current = Node(stack.pop());
			nodes.push(current);
			for(i = 0; i < current.children.length; i++)
			{
				stack.push(current.children[i]);
			}
		}
		// Sort the array by id in ascending order
		nodes.sort(function compare(x:Node, y:Node):Number {
			return x.id - y.id;
		});
		// Add data to the qgroup
		for(i = 0; i < nodes.length; i++)
		{
			// if no data exists for this node, skip it
			if(nodes[i].isShortcut || nodes[i].data == null) continue;
			// store reference to question data
			var data:Question = nodes[i].data.clone();
			// store id as an option
			data.options.id = nodes[i].id;
			// fill in empty answers (so server code doesn't auto-delete them)
			for(j = 0; j < nodes[i].children.length; j++)
			{
				// Add dummy data for empty nodes with child node
				if(data.answers == null) data.answers = new Array();
				if(data.answers.length <= j)
				{
					data.answers.push(new Object());
					data.answers[j].value = "0";
					data.answers[j].options = new Object();
					data.answers[j].options.link = nodes[i].children[j].id;
					data.answers[j].options.dummyData = true;
				}
				// Add default text to empty answers
				if(data.answers[j].text == null || data.answers[j].text.length == 0)
				{
					data.answers[j].text = Creator.DEFAULT_ANSWER;
				}
				// Keep track of what paths are shortcuts (to preserve exact structure when editing)
				if(nodes[i].children[j].isShortcut)
				{
					data.answers[j].options.isShortcut = true;
					data.answers[j].options.link = nodes[i].children[j].shortcut;
				}
			}
			// add to qgroup
			qGroup.addQuestion(data);
		}
		// Return the qgroup
		return qGroup;
	}
	public function createTreeFromQset(qSet:QuestionGroup):void
	{
		var i:int, j:int, k:int;
		// delete any tree that might currently exist
		clearTree();
		// save reference to the question group
		var qGroup:QuestionGroup = QuestionGroup(qSet.items[0]);
		// find biggest id to establish size of alreadyCreated array
		var maxId:int = 0;
		for(i = 0; i < qGroup.items.length; i++)
		{
			if(qGroup.items[i].options.id > maxId) maxId = qGroup.items[i].options.id;
		}
		// create an array to remember if a node has already been created
		var alreadyCreated:Vector.<Boolean> = new Vector.<Boolean>(maxId + 1, true);
		for(i = 0; i < alreadyCreated.length; i++)
		{
			alreadyCreated[i] = false;
		}
		// create a stack to be used for creating the tree
		var stack:Stack = new Stack();
		var root:Node = new Node(0);
		root.data = (qGroup.items[0] as Question).clone();
		root.type = qGroup.items[0].options.type;
		_root = createDisplayNode(root);
		alreadyCreated[0] = true;
		stack.push(root);
		// Create the Tree (left oriented depth-first)
		while(!stack.isEmpty())
		{
			// get the node from the stack
			var node:Node = Node(stack.pop());
			// nothing to do for nodes that lead nowhere
			if(node.data == null || node.data.answers == null) continue;
			// create the child nodes for this node
			for(i = 0; i < node.data.answers.length; i++)
			{
				var newNode:Node;
				var newId:int = int(node.data.answers[i].options.link);
				// If answer path does not lead to a shortcut, create a real node
				if(node.data.answers[i].options.isShortcut == null || node.data.answers[i].options.isShortcut == false)
				{
					// Create
					newNode = new Node(newId);
					// Find node data in qGroup
					for(j = 0; j < qGroup.items.length; j++)
					{
						if(qGroup.items[j].options.id == newId)
						{
							newNode.data = qGroup.items[j].clone();
							if(newNode.data == null) newNode.resetData();
							// Erase placeholder answers
							for(k = 0; k < newNode.data.answers.length; k++)
							{
								if(newNode.data.answers[k].text == Creator.DEFAULT_ANSWER)
								{
									newNode.data.answers[k].text = "";
								}
							}
							newNode.type = newNode.data.options.type == null ? AdventureOptions.TYPE_NONE : newNode.data.options.type;
							break;
						}
					}
					alreadyCreated[newId] = true;
				}
					// Otherwise, create a shortcut node
				else
				{
					newNode = new Node(_linkIdIncrement++);
					newNode.resetData();
					newNode.shortcut = newId;
				}
				// make sure the node is not marked as new
				if(node.type != AdventureOptions.TYPE_NONE) node.isNew = false;
				// Add the node to the tree
				node.addChild(newNode);
				createDisplayNode(newNode);
				// Manage dummy data (for empty nodes with child node)
				if(node.data.answers[i].options.dummyData)
				{
					node.data.answers.splice(i, 1);
					break;
				}
			}
			// add new children to the stack in reverse order so we do left oriented BFT
			for(i = node.children.length - 1; i >= 0; i--)
			{
				stack.push(node.children[i]);
			}
		}
		/* Manage recovered IDs and link increment by using the alreadyCreated vector */
		for(i = 0; i < alreadyCreated.length; i++)
		{
			if(alreadyCreated[i]) _idIncrement = i + 1;
			else _recoveredIds.push(i);
		}
		// draw the tree
		redraw();
	}
	public function showNodesAsNew(nodes:Array):void
	{
		var i:int;
		/* Don't do anything if given array is empty */
		if(nodes == null || nodes.length == 0) return;
		/* Set all other nodes to stop being marked as new */
		if(_nodesMarkedAsNew != null)
		{
			for(i = 0; i < _nodesMarkedAsNew.length; i++)
			{
				Node(_nodesMarkedAsNew[i]).displayNode.markedAsNew = false;
			}
		}
		/* Set new nodes to be marked as new */
		_nodesMarkedAsNew = nodes;
		var node:Node;
		for(i = 0; i < _nodesMarkedAsNew.length; i++)
		{
			node = Node(_nodesMarkedAsNew[i]);
			if(node.type == AdventureOptions.TYPE_NONE && !node.isShortcut)
			{
				node.displayNode.markedAsNew = true;
			}
		}
		redraw();
	}
	/**
	 * Shows a connector line from one node to the other to demonstrate links
	 */
	public function showLinkLine(p1:Point, p2:Point, bringToTop:Boolean = false):void
	{
		// prepare constants
		const strokeWidth:Number = 2;
		const strokeLength:Number = 9;
		const color:Number = 0xa0a0a0;
		// prepare graphics
		_lineLayer.graphics.clear();
		_lineLayer.graphics.lineStyle(strokeWidth, color);
		// get polar coordinates
		var angle:Number = Math.atan((p2.y - p1.y) / (p2.x - p1.x));
		var dir:int = p2.x - p1.x >= 0 ? 1 : -1;
		var dist:Number = Math.sqrt(Math.pow(p1.x - p2.x, 2) + Math.pow(p1.y - p2.y, 2));
		// draw the dotted line
		for(var i:int = 0, len:int = Math.ceil(Math.abs(dist) / strokeLength); i < len; i += 2)
		{
			var startPoint:Point = new Point(p1.x + (i * dir * strokeLength) * Math.cos(angle), p1.y + (i * dir * strokeLength) * Math.sin(angle));
			_lineLayer.graphics.moveTo(startPoint.x, startPoint.y);
			var drawLength:Number = strokeLength;
			if(i >= len - 2)
			{
				var distToPoint:Number = Point.distance(startPoint, p2);
				drawLength = Math.min(distToPoint, strokeLength);
			}
			_lineLayer.graphics.lineTo(startPoint.x + drawLength * dir * Math.cos(angle), startPoint.y + drawLength * dir * Math.sin(angle));
		}
		// Bring to top if requested
		if(bringToTop) _tree.addChild(_lineLayer);
	}
	/**
	 * Hides all link lines that might be remaining
	 */
	public function hideLinkLines():void
	{
		_lineLayer.graphics.clear();
	}
	/**
	 * Draws the background
	 **/
	private function redrawBg():void
	{
		// draw background
		_bg.graphics.clear();
		_bg.graphics.beginFill(0x0, 0);
		_bg.graphics.drawRect(0,0,_displayArea.width,_displayArea.height);
		_bg.graphics.endFill();
	}
	private function onAddedToStage(e:Event):void
	{
		this.removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		// Keep strong reference to stage
		_stage = this.stage;
		// Store important parent references
		_displayArea = UIComponent(parent);
		_container = Container(_displayArea.parent);
		// Add Event Listeners
		_displayArea.addEventListener(Event.RESIZE, onResize, false, 0, true);
		_container.addEventListener(MouseEvent.MOUSE_WHEEL, onScroll, false, 0, true);
		_bg.addEventListener(MouseEvent.CLICK, onBgClick, false, 0, true);
		if(!_drawComplete) draw();
	}
	private function onResize(e:Event):void
	{
		DisplayNode.resetStandardRadii();
		redraw();
		redrawBg();
	}
	private function draw():void
	{
		// add debug button at bottom
		_debugButton = new Button("Debug");
//		_overlay.addChild(_debugButton);
		_debugButton.addEventListener(MouseEvent.CLICK, onDebugClick, false, 0, true);
		redraw();
		/*
		// draw the legend
		_debugField = new TextField();
		_debugField.defaultTextFormat = new TextFormat("Arial", 18, 0, true);
		_debugField.multiline = true;
		_debugField.text = Creator.VERSION;
		_debugField.selectable = false;
		_debugField.autoSize = TextFieldAutoSize.LEFT;
		_overlay.addChild(_debugField);
		*/
		// create the notification toolbar
		_notificationBar = new NotificationBar();
		_notificationBar.x = _overlay.width / 2 - _notificationBar.width / 2;
		_notificationBar.y = PADDING_V;
		_overlay.addChild(_notificationBar);
		// create the mouse-over bubbles
		_prependBubble = new PrependBubble();
		_prependBubble.addEventListener(MouseEvent.CLICK, onPrependClick, false, 0, true);
		this.addChild(_prependBubble);
		_tracerBubble = new TracerBubble();
		this.addChild(_tracerBubble);
		_nodeBubble = new NodeBubble();
		this.addChild(_nodeBubble);
		// create node toolbar
		_nodeToolbar = new NodeToolbar();
		this.stage.addChild(_nodeToolbar);
		// create hover hotspot
		_hoverHotspot = new Sprite();
		_hoverHotspot.mouseEnabled = false;
		// redraw the background
		redrawBg();
		// mark draw complete flag
		_drawComplete = true;
	}
	private function onDebugClick(e:Event):void
	{
//		_container.verticalScrollPosition = _container.maxVerticalScrollPosition;
//		var temp:AdventureNode = _root.node.clone();
//		_root.node = temp;
		var qgroup:QuestionGroup = generateQGroup("SDLKFJSDKLJ");
		_creator.testImporting();
	}
	/**
	 * Adds a node as a child to the node that was clicked
	 */
	private function onNodeClick(e:MouseEvent):void
	{
		// Only pay attention to clicks on nodes
		if(!(e.target is DisplayNode)) return;
		var node:Node = (e.target as DisplayNode).node;
		node.checkForErrors();
		// Store a reference to the node
		selectNode(node);
	}
	private function onPrependClick(e:MouseEvent):void
	{
		prependNode(PrependBubble(e.target).targetNode);
	}
	/**
	 * Adds a new (empty) node before the given node
	 */
	public function prependNode(nodeToPrepend:Node):void
	{
		// Only allow prepend on nodes with content
		if(nodeToPrepend.isRoot || nodeToPrepend.isEmpty || nodeToPrepend.parent.isEmpty) return;
		var newNode:Node = createDisplayNode(new Node(getNextId())).node;
		newNode.resetData();
		destroyBackupTree();
		nodeToPrepend.prepend(newNode);
		redraw();
	}
	public function selectNode(node:Node):void
	{
		// Hide the node toolbar
		nodeMouseOut();
		// Proceed to edit the node or if in link edit mode, propagate the link choice
		if(linkEditMode)
		{
			manageLinkEdit(node);
		}
		else if(nodeCopyMode)
		{
			copyNode(copyTarget, node.displayNode);
		}
		else
		{
			if(node.isShortcut)
			{
				editNode(node.shortcutTarget);
				//				Dialog.show(Dialog.YESNO, "Edit Shortcut", "Shortcuts can't contain content.\nWould you like to have this shortcut point somewhere else?", function callback():void { editLink(node.id, null); });
			}
			else
			{
				editNode(node);
				destroyBackupTree();
			}
		}
	}
	private function onBgClick(e:Event):void
	{
		cancelCurrentMode();
	}
	/**
	 * Cancels any special modes (link mode, copy mode) and hides the notification bar
	 * @return
	 */
	public function cancelCurrentMode():Boolean
	{
		_notificationBar.hide();
		if(nodeCopyMode) {
			nodeCopyMode = false;
			redraw();
			return true;
		}
		else if(linkEditMode) {
			manageLinkEdit(null);
			return true;
		}
		return false;
	}
	public function editNode(node:Node):void
	{
		nodeMouseOut();
		_creator.editNode(node);
	}
	public function onScroll(e:Event):void
	{
		nodeMouseOut();
	}
	private function onNodeMouseOver(e:Event):void
	{
		// get reference to target node
		var node:Node
		if(e != null) // if event was passed, get node reference from it
		{
			node = DisplayNode(e.target).node;
			_lastNodeHovered = node.displayNode;
		}
		else // if event wasn't passed, get reference node from last hovered
		{
			node = _lastNodeHovered.node;
		}
		// remove toolbar if left over
		if(this.hasEventListener(MouseEvent.MOUSE_MOVE)) nodeMouseOut();
		// don't show in node copy mode
		if(nodeCopyMode) return;
		// determine the message to be shown in the bubble
		var msg:String;
		if(node.data != null && node.data.question.length > 0) msg = node.data.question;
		else if(node.isEmpty) msg = "Click to Add a Destination";
		else if(node.isShortcut) msg = "[Links to " + DisplayNode.idToLabel(node.shortcut) + "]\n";
		else if(!node.isValid) msg = "<b>Warning</b>: " + node.errorMessage;
		else msg = "* This Destination Contains No Text *";
		// show bubble and toolbar
		_nodeBubble.show(node, msg);
		if(!linkEditMode)
		{
			_nodeToolbar.show(node);
		}
		if(!node.isRoot && !node.isEmpty && !node.parent.isEmpty)
		{
			_prependBubble.show(node);
		}
		
		// create hover hotspot (so toolbars won't disappear immediately at mouseOut)
		_hoverHotspot.graphics.clear();
		_hoverHotspot.graphics.beginFill(0, 0);
		var r:Number = Math.max(node.displayNode.height, node.displayNode.width) / 2;
		var point:Point = this.globalToLocal(_tree.localToGlobal(new Point(node.displayNode.x, node.displayNode.y)));
		var prependWidth:int = _prependBubble.width + 10;
		var prependHeight:int = Math.max(PrependBubble.RADIUS * 2 + PrependBubble.SPACING + 5, 0);
		var toolbarPos:Point = globalToLocal(new Point(_nodeToolbar.x, _nodeToolbar.y));
		_hoverHotspot.x = point.x - r;
		_hoverHotspot.y = point.y - r;
		var bufferRoom:int = 25;
		
		_hoverHotspot.graphics.moveTo(r - prependWidth / 2, -prependHeight);
		_hoverHotspot.graphics.lineTo(r + prependWidth / 2, -prependHeight);
		if(!linkEditMode)
		{
			if(point.y < toolbarPos.y) // If the toolbar is below the display node:
			{
				_hoverHotspot.graphics.lineTo(toolbarPos.x + _nodeToolbar.width - _hoverHotspot.x + bufferRoom, toolbarPos.y +  _nodeToolbar.height - _hoverHotspot.y + bufferRoom);
				_hoverHotspot.graphics.lineTo(toolbarPos.x - _hoverHotspot.x - bufferRoom, toolbarPos.y +  _nodeToolbar.height - _hoverHotspot.y + bufferRoom);
			}
			else // toolbar is above the display node
			{
				_hoverHotspot.graphics.lineTo(toolbarPos.x + _nodeToolbar.width - _hoverHotspot.x + bufferRoom, toolbarPos.y - _hoverHotspot.y + bufferRoom);
				_hoverHotspot.graphics.lineTo(r * 2, r * 2);
				_hoverHotspot.graphics.lineTo(0, r * 2);
				_hoverHotspot.graphics.lineTo(toolbarPos.x - _hoverHotspot.x - bufferRoom, toolbarPos.y - _hoverHotspot.y + bufferRoom);
			}
		}
		else
		{
			_hoverHotspot.graphics.lineTo(r * 2, r * 2);
			_hoverHotspot.graphics.lineTo(0, r * 2);
			_hoverHotspot.graphics.moveTo(r - prependWidth / 2, -prependHeight);
		}
		
		this.addChild(_hoverHotspot);
		_stage.addEventListener(MouseEvent.MOUSE_MOVE, onNodeMouseMove, false, 0, true);
		if(!node.isRoot && node.parent.type != AdventureOptions.TYPE_NARRATIVE && node.parent.type != AdventureOptions.TYPE_NONE && node.parent.answersMatchChildren)
		{
			_tracerBubble.show(node);
		}
		// Highlight the branch connecting this node to it's parent
		if(!node.isRoot && node.displayNode.settled)
		{
			_branchHighlightLayer.graphics.clear();
			drawBranchOnSprite(_branchHighlightLayer, node.parent.displayNode, node.displayNode, true);
		}
	}
	private function onNodeMouseMove(e:Event):void
	{
		if(_hoverHotspot == null) return;
		// If we're outside the hotspot trigger removal
		var mousePoint:Point = this.localToGlobal(new Point(this.mouseX, this.mouseY));
		if(!_hoverHotspot.hitTestPoint(mousePoint.x, mousePoint.y, true)) nodeMouseOut();
	}
	private function nodeMouseOut():void
	{
		if(_hoverHotspot == null) return;
		// remove mouse move listener
		if(_stage.hasEventListener(MouseEvent.MOUSE_MOVE)) _stage.removeEventListener(MouseEvent.MOUSE_MOVE, onNodeMouseMove);
		// remove hover hotspot
		if(_hoverHotspot.parent != null) this.removeChild(_hoverHotspot);
		// hide bubbles and toolbar
		_prependBubble.hide();
		_nodeBubble.hide();
		_tracerBubble.hide();
		_nodeToolbar.hide();
		// Un-Highlight the branch connecting this node to it's parent
		_branchHighlightLayer.graphics.clear();
	}
	/**
	 * Called externally to set a link
	 */
	public function setLink(linkFrom:Node, linkTo:Node):void
	{
		if(linkFrom.children.length)
		{
			showLinkError();
			return;
		}
		linkTarget = linkFrom;
		manageLinkEdit(linkTo);
	}
	/**
	 * Called when a link is selected in link edit mode. Link edit mode assumes
	 * there is a target node (the node we're linking from); Here, we finalize
	 * link edit mode by selecting where we're linking to.
	 * @param node The node we should link to
	 */
	private function manageLinkEdit(node:Node):void
	{
		var i:int, linkId:int, id:int, targetParent:Node, linkError:Boolean;
		if(node != null)
		{
			//----------------------------------
			//  Was shortcut but not anymore
			//----------------------------------
			if(linkTarget.isShortcut && node == linkTarget)
			{
				linkId = getNextId();
				// update question data for target node's parent
				targetParent = linkTarget.parent;
				for(i = 0; i < targetParent.children.length; i++)
				{
					if(targetParent.children[i] == linkTarget)
					{
						targetParent.data.answers[i].options.link = linkId;
						break;
					}
				}
				linkTarget.shortcut = -1;
				linkTarget.id = linkId;
			}
			//----------------------------------
			//  Was shortcut; changed to another shortcut
			//----------------------------------
			else if(linkTarget.isShortcut && node != linkTarget)
			{
				// find the new id to link to
				if(node.isShortcut) linkId = node.shortcut; // use path compression to avoid chained links
				else linkId = node.id;
				// avoid "infinite loop" a->b, b->a bug
				if(linkId != linkTarget.id)
				{
					// update question data for target node's parent
					targetParent = linkTarget.parent;
					for(i = 0; i < targetParent.children.length; i++)
					{
						if(targetParent.children[i] == linkTarget)
						{
							targetParent.data.answers[i].options.link = linkId;
							break;
						}
					}
					// link to new node
					linkTarget.shortcut = linkId;
				}
				else
				{
					linkError = true;
				}
			}
			//----------------------------------
			//  Was NOT Shortcut but is now
			//----------------------------------
			else if(!linkTarget.isShortcut && node != linkTarget)
			{
				// revoke "new" status of target node
				linkTarget.isNew = false;
				linkTarget.displayNode.markedAsNew = false;
				// find the new id to link to
				if(node.isShortcut) linkId = node.shortcut; // use path compression to avoid chained links
				else linkId = node.id;
				// avoid "infinite loop" a->b, b->a bug
				if(linkId != linkTarget.id)
				{
					// update question data for target node's parent
					targetParent = linkTarget.parent;
					for(i = 0; i < targetParent.children.length; i++)
					{
						if(targetParent.children[i] == linkTarget)
						{
							targetParent.data.answers[i].options.link = linkId;
							break;
						}
					}
					// chain linking can occur here if a node pointed here... update these links
					redirectLinks(linkTarget, node);
					// save the unique node id that is about to be lost
					_recoveredIds.push(linkTarget.id);
					sortRecoveredIds();
					// get a new unique id that belongs to links
					linkTarget.id = _linkIdIncrement++;
					// link to new node
					linkTarget.shortcut = linkId;
				}
				else
				{
					linkError = true;
				}
			}
			// If infinite loop shortcut was detected, show error and proceed to pick another link
			if(linkError)
			{
				Dialog.show(Dialog.OK, "Error Creating Link", "Linking to this node would result in an infinite cycle.");
				return; // proceed to pick another link
			}
		}
		//----------------------------------
		//  Terminate Link Edit Mode
		//----------------------------------
		_lineLayer.graphics.clear();
		this.removeEventListener(Event.ENTER_FRAME, updateEditLine);
		linkEditMode = false;
		redraw();
		// call the callback function sent by creator if there is one
		if(_editModeCallback != null) _editModeCallback.apply(this);
		_editModeCallback = null;
		// hide the link edit mode instructions
		_notificationBar.hide();
	}
	private function updateLinkTargetPoint():void
	{
		_linkTargetPoint = _lineLayer.globalToLocal(_tree.localToGlobal(new Point(linkTarget.displayNode.x, linkTarget.displayNode.y)));
	}
	private function updateEditLine(e:Event):void
	{
		showLinkLine(_linkTargetPoint, new Point(_lineLayer.mouseX, _lineLayer.mouseY));
	}
	/**
	 * Traverses the entire tree and makes sure any link node pointing to the
	 * oldLink now points to the newLink.
	 */
	private function redirectLinks(oldLink:Node, newLink:Node):void
	{
		// traverse all links and update all links pointing to oldLink to point to newLink
		var stack:Stack = new Stack();
		stack.push(_root.node);
		var i:int;
		while(!stack.isEmpty())
		{
			var current:Node = Node(stack.pop());
			if(current.isShortcut)
			{
				// if a link node pointing to the old link is found
				if(current.shortcut == oldLink.id)
				{
					// change shortcut id
					current.shortcut = newLink.id;
					// update parent's question data
					for(i = 0; i < current.parent.children.length; i++)
					{
						if(current.parent.children[i] == current)
						{
							current.parent.data.answers[i].options.link = newLink.id;
							break;
						}
					}
				}
			}
			else
			{
				for(i = 0; i < current.children.length; i++)
				{
					stack.push(current.children[i]);
				}
			}
		}
	}
	private function createDisplayNode(node:Node):DisplayNode
	{
		// create a new display node
		var result:DisplayNode = new DisplayNode(node);
		// add listeners
		result.doubleClickEnabled = true;
		result.addEventListener(MouseEvent.CLICK, onNodeClick, false, 0, true);
		result.addEventListener(MouseEvent.DOUBLE_CLICK, onNodeClick, false, 0, true);
		result.addEventListener(MouseEvent.MOUSE_OVER, onNodeMouseOver, false, 0, true);
		//result.addEventListener(MouseEvent.MOUSE_OUT, nodeMouseOut, false, 0, true);
		result.addEventListener(DisplayNode.TWEEN_START, onNodeTweenStart, false, 0, true);
		result.addEventListener(DisplayNode.TWEEN_END, onNodeTweenEnd, false, 0, true);
		// add to the tree
		_tree.addChild(result);
		// Keep track of last added node
		_lastAddedNode = result;
		// return reference to new display node
		return result;
	}
	private function sortRecoveredIds():void
	{
		_recoveredIds.sort(function compare(x:int, y:int):int {
			return y - x;
		});
	}
	private function onNodeTweenStart(e:Event):void
	{
		if(_currentTweens == 0 && !this.hasEventListener(Event.ENTER_FRAME))
		{
			this.addEventListener(Event.ENTER_FRAME, onNodesTweening, false, 0, true);
		}
		_currentTweens++;
	}
	private function onNodeTweenEnd(e:Event):void
	{
		_currentTweens--;
	}
	/**
	 * Reposition and redraw all of the nodes in the tree.
	 * Wrapper function for organizeTreeR
	 */
	private function organizeTree():void
	{
		if(_root == null) return;
		// Measure scrollbar width if one exists
		var scrollbarWidth:int = 0;
		if(_container.verticalScrollBar && _container.verticalScrollBar.visible) scrollbarWidth = _container.verticalScrollBar.width;
		// establish desired height and width of levels
		_levelHeight = _displayArea.height / _root.node.treeHeight;
		_levelWidth = _displayArea.width - PADDING_H * 2 - scrollbarWidth;
		// redraw and reorganize the tree
		_tree.graphics.clear();
		organizeTreeR(_root, new Rectangle(0, 0, _levelWidth, 0), 0, 0);
		redrawTree(_root);
	}
	/**
	 * Organizes the tree starting at the given node. Repositions and redraws the node graphic.
	 */
	private function organizeTreeR(current:DisplayNode, parentBounds:Rectangle, level:int, preceedingLeaves:int):void
	{
		var size:int = DisplayNode.radius;
		var parent:Node = current.node.parent;
		if(parent == null) parent = current.node;
		var boundsWidth:Number = parentBounds.width * (current.node.numLeafs / parent.numLeafs);
		current.bounds = new Rectangle(parentBounds.x + preceedingLeaves / parent.numLeafs * parentBounds.width, parentBounds.y + parentBounds.height, boundsWidth, _levelHeight);
		preceedingLeaves = 0;
		for(var i:int = 0; i < current.node.children.length; i++)
		{
			var childNode:Node = current.node.children[i];
			organizeTreeR(childNode.displayNode, current.bounds, level++, preceedingLeaves);
			preceedingLeaves += childNode.numLeafs;
		}
	}
	/**
	 * Redraws the node graphics for the given node and all of its children
	 */
	private function redrawTree(current:DisplayNode):void
	{
		nodeMouseOut();
		current.redraw();
		for(var i:int = 0; i < current.node.children.length; i++)
		{
			redrawTree(current.node.children[i].displayNode);
		}
	}
	/**
	 * Draws a branch connecting the given parent node to the given child node
	 * on the main tree sprite
	 */
	private function drawBranch(parent:DisplayNode, child:DisplayNode, highlight:Boolean = false):void
	{
		drawBranchOnSprite(_tree, parent, child, highlight);
	}
	/**
	 * Draws a branch connecting the given parent node to the given child node
	 * on the given sprite.
	 */
	private function drawBranchOnSprite(sprite:Sprite, parent:DisplayNode, child:DisplayNode, highlight:Boolean = false):void
	{
		var stroke:Number = highlight ? 6 : 2;
		var color:Number = highlight ? 0x70c0c0 : 0x909090;
		sprite.graphics.lineStyle(stroke, color, 1, true, "normal", CapsStyle.NONE);
		sprite.graphics.moveTo(parent.x, parent.y + DisplayNode.radius);
		var midpointY:Number = getMidpointBetweenNodes(parent, child);
		sprite.graphics.lineTo(parent.x, midpointY);
		var direction:int = 0;
		if(parent.node.children.length > 1 && child.node.leftSibling == null) direction = -1;
		else if (parent.node.children.length > 1 && child.node.rightSibling == null) direction = 1;
		sprite.graphics.lineTo(child.x - EDGE_CURVE * direction, midpointY);
		if(direction != 0) sprite.graphics.curveTo(child.x, midpointY, child.x, midpointY + EDGE_CURVE);
		sprite.graphics.lineTo(child.x, child.y - DisplayNode.radius);
	}
	/**
	 * Called once for every frame a node is tweening.
	 */
	private function onNodesTweening(e:Event):void
	{
		// Updates position of hover hotspot and node toolbar if user
		// mouses over during a tween (so node toolbar follows tweening node)
		if(_lastNodeHovered != null && _hoverHotspot.parent != null)
		{
			onNodeMouseOver(null); // updates position of node toolbar & hover hotspot
			onNodeMouseMove(null); // hides node toolbar if tween moves node out of mouses way
		}
		// Redraw the branches on every frame of tween
		drawBranches(null);
		// eliminate enter-frame listener when all tweens are done
		if(_currentTweens == 0 && this.hasEventListener(Event.ENTER_FRAME))
		{
			this.removeEventListener(Event.ENTER_FRAME, onNodesTweening);
		}
	}
	/**
	 * Draws all the branches for the display tree.
	 * This is a wrapper function for drawBranchesR
	 */
	private function drawBranches(e:Event = null):void
	{
		_tree.graphics.clear();
		drawBranchesR(_root);
		if(linkEditMode) updateLinkTargetPoint();
	}
	/**
	 * Draws all the branches for the tree under the given display node
	 */
	private function drawBranchesR(current:DisplayNode):void
	{
		for(var i:int = 0; i < current.node.children.length; i++)
		{
			var childNode:DisplayNode = current.node.children[i].displayNode;
			if(!childNode.settled) continue; // don't draw the line if the node is tweening
			drawBranchesR(childNode);
			drawBranch(current, childNode);
		}
	}

	public function validateEndNodes():Boolean
	{
		// work through all nodes in tree
		for (var i:int=0; i<_tree.numChildren; i++)
		{
			if (_tree.getChildAt(i) is DisplayNode)
			{
				var nodeToCheck:DisplayNode = _tree.getChildAt(i) as DisplayNode;

				// if the node is NOT an End Node and the node has no children, INVALIDATE THAT HOE (giiirl)
				if (nodeToCheck.node.type != 5 && nodeToCheck.node.children.length == 0 && nodeToCheck.node.isShortcut == false)
				{
					return false;
				}
			}
		}
		return true;
	}
	
	// Utility function to get the midpoint between two display nodes
	public static function getMidpointBetweenNodes(fromNode:DisplayNode, toNode:DisplayNode):Number
	{
		return fromNode.y + fromNode.bounds.height / 2 + ((toNode.y - toNode.bounds.height / 2) - (fromNode.y + fromNode.bounds.height / 2)) / 2;
	}
}
}