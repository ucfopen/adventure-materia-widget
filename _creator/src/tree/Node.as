package tree {
import materia.questionStorage.Question;
public class Node
{
	//--------------------------------------------------------------------------
	//
	//  Instance Variables
	//
	//--------------------------------------------------------------------------
	public var parent:Node;
	public var leftSibling:Node;
	public var rightSibling:Node;
	public var children:Vector.<Node> = new Vector.<Node>();
	public var numLeafs:int = 1;
	public var treeHeight:int = 1;
	public var displayNode:DisplayNode;
	public var imported:Boolean;
	public var data:Question;
	public var type:int = AdventureOptions.TYPE_NONE;
	public var isNew:Boolean = true;
	/**
	 * True if there is an existing non-obvious error (different reasons for each type)
	 */
	private var _customError:Boolean = false;
	private var _customErrorMessage:String = null;
	private var _id:int;
	private var _shortcut:int = -1;
	private var _shortcutTarget:Node;
	//--------------------------------------------------------------------------
	//
	//  Constructor
	//
	//--------------------------------------------------------------------------
	public function Node(id:int)
	{
		this._id = id;
	}
	//--------------------------------------------------------------------------
	//
	//  Accessor Functions
	//
	//--------------------------------------------------------------------------
	public function get id():int { return _id; }
	public function set id(val:int):void { _id = val; if(val < Creator.LINK_ID_START) data.addOption("id", val); }
	public function get isRoot():Boolean { return parent == null; }
	public function get isLeaf():Boolean { return children.length == 0; }
	public function get isEndNode():Boolean { return this.type == AdventureOptions.TYPE_END }
	public function get isEmpty():Boolean { return !isShortcut && type == AdventureOptions.TYPE_NONE; }
	public function get isShortcut():Boolean { return shortcut != -1; }
	public function get answersMatchChildren():Boolean { return this.children.length == this.data.answers.length; }
	public function get isValid():Boolean
	{
		return !_customError &&                                    // check for type-specific errors
			(children.length != 0 || isShortcut || isEndNode) &&   // make sure it has children
			this.answersMatchChildren;                             // make sure children match answers
	}
	public function get errorMessage():String
	{
		if(_customErrorMessage) return _customErrorMessage;
		if(!(children.length != 0 || isShortcut || isEndNode)) return "This destination must lead somewhere. Click to add a path.";
		if(!this.answersMatchChildren)
		{
			if(this.type == AdventureOptions.TYPE_HOTSPOT) return "This destination leads somewhere but there is no hotspot attached to the path. Click to add a hotspot";
			else return "This destination leads somewhere but there is no answer attached to the path. Click to add an answer";
		}
		return "There is something missing here"; // should never get here
	}
	/**
	 * The id of the effective node (this one if not shortcut, shortcut's id otherwise)
	 */
	public function get targetId():int { return isShortcut ? shortcut : id; }
	/**
	 * The Node ID of the shortcut we're linking to
	 */
	public function get shortcut():int { return _shortcut; }
	public function set shortcut(val:int):void { _shortcut = val; _shortcutTarget = null; }
	/**
	 * The node reference to the shortcut we're linking to
	 */
	public function get shortcutTarget():Node
	{
		// return null if not a shortcut
		if(!isShortcut || displayNode == null) return null;
		// return shortcut link if exists
		if(_shortcutTarget != null) return _shortcutTarget;
		// return new shortcut link and save for future reference
		_shortcutTarget = displayNode.displayTree.getNodeFromId(shortcut);
		return _shortcutTarget;
	}
	//--------------------------------------------------------------------------
	//
	//  Member Functions
	//
	//--------------------------------------------------------------------------
	//----------------------------------
	//  Node Management
	//----------------------------------
	public function addChild(node:Node):Node
	{
		// update numLeaves and treeHeight for each parent node to root
		var leavesAdded:int = node.numLeafs - (isLeaf ? 1 : 0);
		var current:Node = this;
		var previous:Node = node;
		while(current != null)
		{
			current.numLeafs += leavesAdded;
			current.treeHeight = Math.max(current.treeHeight, previous.treeHeight + 1);
			previous = current;
			current = current.parent;
		}
		// update sibling references
		var leftChild:Node;
		if(children.length)
		{
			leftChild = children[children.length-1];
			leftChild.rightSibling = node;
		}
		node.leftSibling = leftChild;
		// add the node to list of children
		children.push(node);
		// update the new node's parent reference
		node.parent = this;
		return node;
	}
	public function removeChild(node:Node):Boolean
	{
		// find the given node in list of children and remove it
		for(var pos:int = 0; pos < children.length; pos++)
		{
			if(children[pos] == node)
			{
				removeChildAt(pos);
				return true;
			}
		}
		return false;
	}
	public function removeChildAt(index:int):Boolean
	{
		// remove the node from list of children
		var node:Node = children.splice(index, 1)[0];
		// update sibling pointers
		if(node.leftSibling != null) node.leftSibling.rightSibling = node.rightSibling;
		if(node.rightSibling != null) node.rightSibling.leftSibling = node.leftSibling;
		// remove node reference in data
		this.data.answers.splice(index, 1);
		this.data.id = 0;
		// update numLeaves and treeHeight for each parent node to root
		var current:Node = this;
		var leavesLost:int = Math.max(1, node.numLeafs) - (current.isLeaf ? 1 : 0);
		while(current != null)
		{
			current.numLeafs -= leavesLost;
			current.treeHeight = current.getNewTreeHeight();
			current = current.parent;
		}
		// update the node's parent reference
		if(node.parent == this) node.parent = null;
		return true; // the child was successfuly removed
	}
	/**
	 * Replaces a node with another node. The node to delete must be a direct child of this node
	 */
	public function replaceChild(oldNode:Node, newNode:Node):Boolean
	{
		// remove newNode from its previous tree (if it has one)
		if(newNode.parent != null) newNode.parent.removeChild(newNode);
		// replace node in list of children
		var isDirectChild:Boolean = false;
		for(var pos:int = 0; pos < children.length; pos++)
		{
			if(children[pos] == oldNode)
			{
				isDirectChild = true;
				children[pos] = newNode;
				// update sibling pointers
				if(oldNode.leftSibling != null) oldNode.leftSibling.rightSibling = newNode;
				if(oldNode.rightSibling != null) oldNode.rightSibling.leftSibling = newNode;
				newNode.leftSibling = oldNode.leftSibling;
				newNode.rightSibling = oldNode.rightSibling;
				// replace node reference in data
				if(newNode.isShortcut) this.data.answers[pos].options.link = newNode.shortcut;
				else if (this.data.answers.length > pos) this.data.answers[pos].options.link = newNode.data.options.id;
				break;
			}
		}
		if(!isDirectChild) return false;
		// update numLeaves and treeHeight for each parent node to root
		var current:Node = this;
		var leafDelta:int = Math.max(1, newNode.numLeafs) - Math.max(1, oldNode.numLeafs);
		while(current != null)
		{
			current.numLeafs += leafDelta;
			current.treeHeight = current.getNewTreeHeight();
			current = current.parent;
		}
		// update the nodes' parent references
		if(oldNode.parent == this) oldNode.parent = null;
		newNode.parent = this;
		return true; // the child was successfuly replaced
	}
	/**
	 * Adds the given node above this one (in between this and parent)
	 */
	public function prepend(node:Node):void
	{
		var indexPos:int = this.parent.getChildIndex(this);
		// update parent/child references
		node.parent = this.parent;
		this.parent.children[indexPos] = node;
		this.parent = node;
		node.children.push(this);
		// update answer link in parent
		if(node.parent.data.answers.length && node.parent.data.answers[indexPos] != null)
		{
			node.parent.data.answers[indexPos].options.link = node.id;
		}
		// Update sibling references
		node.leftSibling = this.leftSibling;
		node.rightSibling = this.rightSibling;
		if(this.leftSibling) this.leftSibling.rightSibling = node;
		if(this.rightSibling) this.rightSibling.leftSibling = node;
		this.leftSibling = this.rightSibling = null;
		// update tree height
		var current:Node = node;
		while(current != null)
		{
			current.treeHeight += 1;
			current = current.parent;
		}
		// update numLeafs
		node.numLeafs = this.numLeafs;
	}
	//----------------------------------
	//  Data Management
	//----------------------------------
	/**
	 * Resets the question data for this node
	 */
	public function resetData():Question
	{
		this.data = new Question("MC", {id:_id}, 0, "");
		return data;
	}
	/**
	 * Checks if there are any type-specific errors with the given node
	 * and flags them. Removes flag if there are no errors.
	 */
	public function checkForErrors():void
	{
		var hasErrors:Boolean = false;
		switch(this.type)
		{
			case AdventureOptions.TYPE_SHORT_ANSWER:
				if((!this.data.answers.length || !this.data.answers[0].options.isDefault))
				{
					_customError = true;
					_customErrorMessage = "The default answer for this destination is missing. Please click to add one";
					return;
				}
				break;
		}
		// if no error was found, unset the custom error flag
		_customError = false;
		_customErrorMessage = null;
	}
	//----------------------------------
	//  Node Information
	//----------------------------------
	/**
	 * Gets the index of the given node in the children array
	 * @return Index of given node. -1 if given node is not a child of this node
	 */
	public function getChildIndex(node:Node):int
	{
		for(var i:int = 0; i < children.length; i++)
		{
			if(node == children[i]) return i;
		}
		return -1;
	}
	/**
	 * Clones this node and all of its children
	 */
	public function clone():Node
	{
		var result:Node = new Node(this.id);
		result.data = this.data.clone();
		result.type = this.type;
		result.shortcut = this.shortcut;
		result.isNew = this.isNew;
		var temp:Node;
		for(var i:int = 0; i < this.children.length; i++)
		{
			temp = this.children[i].clone();
			result.addChild(temp); // <-- manages tree-height & num-leaves for you
		}
		return result;
	}
	private function getNewTreeHeight():int
	{
		if(isLeaf) return 1;
		var max:int = 0;
		for(var i:int = 0; i < children.length; i++)
		{
			if(Node(children[i]).treeHeight > max)
			{
				max = Node(children[i]).treeHeight;
			}
		}
		return max + 1;
	}
}
}