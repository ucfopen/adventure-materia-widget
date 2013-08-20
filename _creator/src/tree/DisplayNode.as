package tree {
import com.gskinner.motion.GTween;
import com.gskinner.motion.easing.Elastic;
import flash.display.Bitmap;
import flash.display.PixelSnapping;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.filters.BitmapFilterQuality;
import flash.filters.GlowFilter;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFormat;
public class DisplayNode extends Sprite
{
	//--------------------------------------------------------------------------
	//
	//  Embedded Images
	//
	//--------------------------------------------------------------------------
	[Embed (source="../assets/empty.png")]
	public static const IMAGE_EMPTY:Class;
	[Embed (source="../assets/link.png")]
	public static const IMAGE_LINK:Class;
	[Embed (source="../assets/hotspot.png")]
	public static const IMAGE_HOTSPOT:Class;
	[Embed (source="../assets/mc.png")]
	public static const IMAGE_MC:Class;
	[Embed (source="../assets/start.png")]
	public static const IMAGE_START:Class;
	[Embed (source="../assets/end.png")]
	public static const IMAGE_END:Class;
	[Embed (source="../assets/narration.png")]
	public static const IMAGE_NARRATION:Class;
	[Embed (source="../assets/shortanswer.png")]
	public static const IMAGE_SHORTANSWER:Class;
	[Embed (source="../assets/warning-small.png")]
	public static const IMAGE_WARNING:Class;
	[Embed (source="../assets/new.png")]
	public static const IMAGE_NEW:Class;
	//--------------------------------------------------------------------------
	//
	//  Class Constants
	//
	//--------------------------------------------------------------------------
	public static const EVENT_FIND_LINK:String = "event-find-link";
	public static const RADIUS_STANDARD:Number = 32;  // radius of all nodes before scaling
	public static const RADIUS_MAX:Number = 32;  // max radius of nodes after scaling
	public static const RADIUS_MIN:Number = 15;  // min radius of nodes after scaling
	public static const RADIUS_MIN_START:Number = 20;
	public static const PADDING_V:Number = 20;
	public static const PADDING_H:Number = 8;
	public static const TWEEN_START:String = "startTween";
	public static const TWEEN_END:String = "endTween";
	public static const TWEEN_DELAY:Number = .5;
	protected static const FILTERSET_NORMAL:Array = [];
	protected static const FILTERSET_HIGHLIGHT:Array = [new GlowFilter(0x0, .5, 10, 10)];
	protected static const FILTERSET_COPY_NORMAL:Array = [new GlowFilter(0x0, .7, 6, 6), new GlowFilter(0x00ff00, .5, 9, 9)];
	protected static const FILTERSET_COPY_HIGHLIGHT:Array = [new GlowFilter(0x0, .7, 6, 6), new GlowFilter(0x00ff00, .7, 14, 14)];
	protected static const FILTERSET_EMPTY_HIGHLIGHT:Array = [new GlowFilter(0x70c0c0, .6, 25, 25)];
	protected static const ALPHA_NORMAL:Number = 1;
	protected static const ALPHA_LOW:Number = .6;
	protected static const ALPHA_MID:Number = 1;
	protected static const EASE_BOUNCY:Function = Elastic.easeOut;
	protected static const TEXT_SIZE_CENTER_LARGE:int = 60;
	protected static const TEXT_SIZE_CENTER_SMALL:int = 38;
	protected static const TEXT_SIZE_SIDE_LARGE:int = 38;
	protected static const TEXT_SIZE_SIDE_SMALL:int = 20;
	protected static const TEXT_SIZE_ROOT:int = 20;
	protected static const FONT_FAMILY:String = null;
	protected static const FILTERSET_LABEL:Array = [new GlowFilter(0xffffff, 1, 2, 2, 100, BitmapFilterQuality.HIGH)];
	//--------------------------------------------------------------------------
	//
	//  Static Variables
	//
	//--------------------------------------------------------------------------
	public static var radius:Number = RADIUS_MAX;
	//--------------------------------------------------------------------------
	//
	//  Instance Variables
	//
	//--------------------------------------------------------------------------
	public var node:Node;
	/**
	 * True if initial tween after creation was completed. Ignores all subsequent tweens.
	 */
	public var settled:Boolean = false; // false if this is a new node
	/**
	 * True when tweening; false otherwise.
	 */
	public var tweening:Boolean = false;
	public var allowFlags:Boolean = true;
	public var markedAsNew:Boolean = false;
	protected var _drawCentered:Boolean = true;
	protected var _image:Sprite;
	protected var _newStar:Sprite;
	protected var _bounds:Rectangle = new Rectangle();
	protected var _highlighted:Boolean = false;
	protected var _moveTween:GTween;
	protected var _label:TextField;
	protected var _warningIcon:Bitmap;
	//--------------------------------------------------------------------------
	//
	//  Accessor Functions
	//
	//--------------------------------------------------------------------------
	public function get bounds():Rectangle { return _bounds; }
	public function set bounds(bounds:Rectangle):void
	{
		_bounds = bounds;
		var calculatedRadius:Number = Math.max(RADIUS_MIN, Math.min(RADIUS_MAX, _bounds.width / 2 - PADDING_H, _bounds.height / 2 - PADDING_V));
		DisplayNode.radius = Math.min(calculatedRadius, radius);
	}
	public function get color():Number
	{
		if(displayTree.linkEditMode) // Different colors in link edit mode
		{
			if(displayTree.linkTarget == node) return NodeColors.GREEN;  // color for item to be linked
			else return NodeColors.RED;                                  // color for all other items
		}
		else if(node.children.length) return NodeColors.BLUE;
		else if (node.isShortcut) return NodeColors.GREEN;
		else return NodeColors.GRAY;
	}
	public function get displayTree():DisplayTree
	{
		return DisplayTree(parent.parent);
	}
	//--------------------------------------------------------------------------
	//
	//  Member Functions
	//
	//--------------------------------------------------------------------------
	public function DisplayNode(node:Node)
	{
		// store reference to data node and callback
		if(node != null)
		{
			this.node = node;
			this.node.displayNode = this;
		}
		doubleClickEnabled = true;
		updateFilters();
		// create and customize label
		_label = new TextField();
		_label.visible = false;
		_label.mouseEnabled = false;
		var desiredLabel:String = "TT";//node != null ? idToLabel(node.id) : "SDFSF";
		_label.defaultTextFormat = new TextFormat("Arial", (desiredLabel.length == 1 ? TEXT_SIZE_SIDE_LARGE : TEXT_SIZE_SIDE_SMALL), 0xffffff, true);
		_label.text = desiredLabel;
		_label.autoSize = TextFieldAutoSize.CENTER;
		_label.filters = FILTERSET_LABEL;
		this.addChildAt(_label, 0);
		// add interaction listeners
		addEventListener(MouseEvent.MOUSE_OVER, onMouseOver, false, 0, true);
		addEventListener(MouseEvent.MOUSE_OUT, onMouseOut, false, 0, true);
//		addEventListener(MouseEvent.CLICK, onClick, false, 0, true);
	}
	/**
	 * Converts an id number to a display label using letters as a number base system.
	 * Special exception for id 0.
	 * 0:"Start", 1:"A", 2:"B", ..., 26:"Z", 27:"AA", 28:"AB", ..., N:"**"
	 */
	public static function idToLabel(id:int):String
	{
		/* Make 0 a special case for start node */
		if(id == 0) return "Start";
		id--;
		/* Find the label for all other nodes (we use letters as digits for base 26) */
		if(id < 26) return String.fromCharCode(id + 65);
		else return (idToLabel(id / 26)) + idToLabel(id % 26 + 1);
	}
	public static function resetStandardRadii():void
	{
		DisplayNode.radius = RADIUS_MAX;
	}
	public function addChildNode(newNode:DisplayNode):DisplayNode
	{
		this.node.addChild(newNode.node);
		return newNode;
	}
	public function updateFilters():void
	{
		if(this.parent == null) return;
		/* If Tree is in Copy Mode */
		if(displayTree.nodeCopyMode || displayTree.nodeImportMode)
		{
			/* Node is Empty */
			if(node.isEmpty)
			{
				this.alpha = ALPHA_NORMAL;
				if(_highlighted) this.filters = FILTERSET_COPY_HIGHLIGHT;
				else this.filters = FILTERSET_COPY_NORMAL;
			}
			/* Node is Not Empty */
			else
			{
				this.alpha = ALPHA_LOW;
				this.mouseEnabled = false;
			}
		}
		/* If Tree is in Normal Mode */
		else
		{
			this.mouseEnabled = true;
			/* Node is Empty */
			if(node.isEmpty)
			{
				if(!_highlighted)
				{
					this.filters = FILTERSET_NORMAL;
//					if(!node.isRoot) this.alpha = ALPHA_LOW;
				}
				else
				{
					this.filters = FILTERSET_EMPTY_HIGHLIGHT;
					if(!node.isRoot) this.alpha = ALPHA_MID;
				}
			}
			/* Node is Not Empty */
			else
			{
				if(_highlighted) this.filters = FILTERSET_HIGHLIGHT;
				else this.filters = FILTERSET_NORMAL;
				this.alpha = ALPHA_NORMAL;
			}
		}
	}
	public function drawShape(shapeRadius:Number = NaN):void
	{
		/* update the desired radius */
		var radius:Number = isNaN(shapeRadius) ? DisplayNode.radius : shapeRadius;
		/* clear old graphics */
		if(_image != null) { removeChild(_image);}
		/* load the desired image */
		_image = new Sprite();
		_image.mouseEnabled = false;
		var bitmap:Bitmap;
		/* use variables for most likely cases */
		var useFilters:Boolean = true;
		var hangLetterToRight:Boolean = true;
		// shortcut node
		if(node.isShortcut)
		{
			_label.setTextFormat(getTextFormat(0xabc4c9));
			var labelX:Number = -_label.width / 2 + (node.shortcut == 0 ? 20 : 5);
			positionLabel(labelX, -_label.height / 2);
			useFilters = false;
			hangLetterToRight = false;
			bitmap = new IMAGE_LINK();
		}
		// empty start node
		else if(node.isRoot && node.isEmpty)
		{
			_label.setTextFormat(new TextFormat(FONT_FAMILY, TEXT_SIZE_ROOT, 0xffffff));
			positionLabel(-_label.width / 2, -_label.height / 2);
			hangLetterToRight = false;
			useFilters = false;
			bitmap = new IMAGE_START();
		}
		// narrative node
		else if(node.type == AdventureOptions.TYPE_NARRATIVE)
		{
			_label.setTextFormat(getTextFormat(0xaddaa4));
			bitmap = new IMAGE_NARRATION();
		}
		// multiple choice node
		else if(node.type == AdventureOptions.TYPE_MULTIPLE_CHOICE)
		{
			_label.setTextFormat(getTextFormat(0xaddaa4));
			bitmap = new IMAGE_MC();
		}
		// hotspot node
		else if(node.type == AdventureOptions.TYPE_HOTSPOT)
		{
			_label.setTextFormat(getTextFormat(0xb97fc6));
			bitmap = new IMAGE_HOTSPOT();
		}
		// short answer node
		else if(node.type == AdventureOptions.TYPE_SHORT_ANSWER)
		{
			_label.setTextFormat(getTextFormat(0x73a0aa));
			bitmap = new IMAGE_SHORTANSWER;
		}
		// end node
		else if(node.type == AdventureOptions.TYPE_END)
		{
			_label.setTextFormat(getTextFormat(0xe5e5e5));
			positionLabel(-_label.width / 2, -_label.height / 2);
			hangLetterToRight = false;
			useFilters = false;
			bitmap = new IMAGE_END;
		}
		// empty node
		else
		{
//			this.alpha = ALPHA_LOW;
			hangLetterToRight = false;
			_label.setTextFormat(getTextFormat(0xe5e5e5));
			positionLabel(-_label.width / 2, -_label.height / 2);
			bitmap = new IMAGE_EMPTY;
		}
		/* manage most likely cases */
		if(useFilters && !_label.filters.length) _label.filters = FILTERSET_LABEL;
		else if(!useFilters && _label.filters.length) _label.filters = [];
		if(hangLetterToRight) positionLabel(RADIUS_STANDARD - _label.width / 2, -_label.height / 2);
		/* draw the graphics */
		bitmap.pixelSnapping = PixelSnapping.NEVER;
		bitmap.smoothing = true;
		if(_drawCentered)
		{
			this.graphics.drawRoundRect(-RADIUS_STANDARD, -RADIUS_STANDARD, RADIUS_STANDARD * 2, RADIUS_STANDARD * 2, 10);
		}
		else
		{
			this.graphics.drawRoundRect(0, 0, RADIUS_STANDARD * 2, RADIUS_STANDARD * 2, 10);
		}
		this.scaleY = this.scaleX = radius / (bitmap.width / 2);
		/* center the image */
		if(_drawCentered)
		{
			bitmap.x = -bitmap.width / 2;
			bitmap.y = -bitmap.height / 2;
		}
		/* add the image */
		_image.addChild(bitmap);
		this.addChildAt(_image, 0);
	}
	public function redraw():void
	{
		// set up graphics
		graphics.clear();
		//graphics.beginFill(color); TODO: erase the color function
		// adjust the label text if needed
		var desiredLabel:String;
		desiredLabel = idToLabel(node.targetId);
		if(_label.text != desiredLabel)
		{
			_label.text = desiredLabel;
		}
		_label.visible = true;
		// add or remove visual flags
		if(allowFlags)
		{
			showWarningFlag(!node.isValid && !node.isEmpty);
			showNewFlag(markedAsNew);
		}
		// draw the shape & filters for this node
		drawShape();
		updateFilters();
		// set initial position for new nodes
		if(x == 0 && y == 0)
		{
			if(node.isRoot)
			{
				this.x = bounds.x + bounds.width / 2;
				this.y = bounds.y + bounds.height / 2;
			}
			else
			{
				this.x = node.parent.displayNode.x;
				this.y = node.parent.displayNode.y;
			}
		}
		/* tween to new position */
		// find new position for x/y
		var newX:Number = (bounds.x + bounds.width / 2);
		var newY:Number = (bounds.y + bounds.height / 2);
		// adjust old tween if it exists
		if(_moveTween != null)
		{
			_moveTween.resetValues({x:newX, y:newY});
		}
		else // create new tween otherwise
		{
			_moveTween = new GTween(this, TWEEN_DELAY, {x:newX, y:newY});
			_moveTween.onComplete = function(t:GTween):void
			{
				_moveTween = null;
				settled = true;
				tweening = false;
				dispatchEvent(new Event(TWEEN_END));
			}
			tweening = true;
			dispatchEvent(new Event(TWEEN_START));
		}
	}

	protected function showNewFlag(val:Boolean):void
	{
		if(_newStar == null && val)
		{
			var bitmap:Bitmap = new IMAGE_NEW;
			bitmap.pixelSnapping = PixelSnapping.NEVER;
			bitmap.smoothing = true;
			bitmap.x = RADIUS_STANDARD / 4;
			this.scaleY = this.scaleX = radius / (bitmap.width / 2);
			_newStar = new Sprite();
			_newStar.mouseEnabled = false;
			_newStar.filters = [new GlowFilter(0, 0.8, 3, 3, 1.5, 2)];
			_newStar.addChild(bitmap);
			this.addChild(_newStar);
		}
		else if(_newStar != null && !val)
		{
			_newStar.removeChildAt(0);
			this.removeChild(_newStar);
			_newStar = null;
		}
	}
	protected function showWarningFlag(val:Boolean):void
	{
		if(val)
		{
			if(_warningIcon == null)
			{
				_warningIcon = new IMAGE_WARNING;
				this.addChild(_warningIcon);
			}
			_warningIcon.x = - radius + 2;
			_warningIcon.y = radius - _warningIcon.height - 2;
			_warningIcon.visible = true;
		}
		else
		{
			if(_warningIcon != null) _warningIcon.visible = false;
		}
	}
	protected function getTextFormat(color:Number = 0xffffff):TextFormat
	{
		if(node.isEmpty) return new TextFormat(FONT_FAMILY, _label.text.length == 1 ? TEXT_SIZE_CENTER_LARGE : TEXT_SIZE_CENTER_SMALL, color, true);
		return new TextFormat(FONT_FAMILY, _label.text.length == 1 ? TEXT_SIZE_SIDE_LARGE : TEXT_SIZE_SIDE_SMALL, color, true);
	}
	protected function positionLabel(labelX:Number, labelY:Number):void
	{
		// adjust position of label
		if(_drawCentered)
		{
			_label.x = labelX;
			_label.y = labelY;
		}
		else
		{
			_label.x = labelX + RADIUS_STANDARD;
			_label.y = labelY + RADIUS_STANDARD;
		}
	}
	protected function onClick(e:Event):void
	{
	}
	protected function onMouseOver(e:Event):void
	{
		// bring node to front (above link lines)
		if(displayTree.linkEditMode) parent.addChild(this);
//		if(displayTree.nodeImportMode) displayTree.lastHovered = this;
		_highlighted = true;
		updateFilters();
		if(node.isShortcut)
		{
			// Get reference to other node
			var other:DisplayNode = node.shortcutTarget.displayNode;
			// Make sure link line won't intersect with branch lines
			var displacement:int = 7;
			var a:Point = new Point(this.x, this.y);
			var b:Point = new Point(other.x, other.y);
			if(a.x == b.x) a.x = b.x = a.x - displacement;
			// Show the link line
			displayTree.showLinkLine(new Point(a.x, a.y), new Point(b.x, b.y), true);
			// Move this node and partner to top to show over link line
			parent.addChild(this);
			parent.addChild(other);
		}
	}
	protected function onMouseOut(e:Event):void
	{
		// send node to back (behind link lines)
		if(displayTree.linkEditMode && this != displayTree.linkTarget.displayNode) parent.addChildAt(this, 0);
		_highlighted = false;
		updateFilters();
		if(node.isShortcut) displayTree.hideLinkLines();
	}
}
}
class Shapes
{
	public static const CIRCLE:int = 0;
	public static const SQUARE:int = 1;
	public static const TRIANGLE:int = 2;
}
class NodeColors
{
	public static const RED:Number = 0xaa2424;
	public static const GREEN:Number = 0x7dd43e;
	public static const BLUE:Number = 0x377aa6;
	public static const YELLOW:Number = 0xFFFC4A;
	public static const GRAY:Number = 0x4b4b4b;
}