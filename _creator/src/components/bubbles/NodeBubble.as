package components.bubbles {
	import tree.DisplayNode;
	import tree.Node;
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.filters.DropShadowFilter;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
public class NodeBubble extends Sprite
{
	private static const COLOR_BG:Number = 0x729fa9;
	private static const FILTERSET_DEFAULT:Array = [new DropShadowFilter(4, 45, 0, .5)];
	private static const WIDTH:Number = 250;
	private static const TEXT_FORMAT:TextFormat = new TextFormat("Arial", 12, 0xffffff);
	private static const NODE_SPACING_RIGHT:Number = 20;
	private static const NODE_SPACING_LEFT:Number = 10;
	private static const PADDING:Number = 10;
	private static const TIP_WIDTH:Number = 12;
	private static const TIP_HEIGHT:Number = 18;
	private static const MAX_CHARS:int = 300;
	private static const CORNER_RADIUS:Number = 10;
	private var _tf:TextField;
	public function NodeBubble()
	{
		// initialize bubble
		this.visible = false;
		this.filters = FILTERSET_DEFAULT;
		// initialize text field
		_tf = new TextField();
		_tf.multiline = true;
		_tf.wordWrap = true;
		_tf.width = WIDTH - PADDING * 2;
		_tf.autoSize = TextFieldAutoSize.CENTER;
		_tf.x = PADDING;
		_tf.y = PADDING;
		_tf.selectable = false;
		_tf.defaultTextFormat = TEXT_FORMAT;
		addChild(_tf);
	}
	public function show(node:Node, msg:String):void
	{
		if(this.parent == null) return;
		var target:DisplayNode = node.displayNode;
		// draw text
		if(msg.length > MAX_CHARS) msg = msg.substr(0, MAX_CHARS) + "...";
		_tf.width = WIDTH - PADDING * 2;
		_tf.htmlText = msg;
		_tf.width = _tf.width = _tf.textWidth + PADDING;
		// draw bubble
		this.visible = false;
		this.graphics.clear();
		this.graphics.beginFill(COLOR_BG);
		var drawWidth:Number = _tf.textWidth + PADDING * 2;
		this.graphics.drawRoundRect(0, 0, drawWidth, _tf.height + PADDING * 2, CORNER_RADIUS);
		var point:Point = this.parent.globalToLocal(target.parent.localToGlobal(new Point(target.x, target.y)));
		// position
		if(point.x < target.displayTree.width / 2)
		{
			// Move to right side of node
			this.x = point.x + DisplayNode.radius + NODE_SPACING_RIGHT + TIP_WIDTH;
			// Draw Tip
			this.graphics.moveTo(0, this.height / 2 - TIP_HEIGHT / 2);
			this.graphics.lineTo(-TIP_WIDTH, this.height / 2);
			this.graphics.lineTo(0, this.height / 2 + TIP_HEIGHT / 2);
		}
		else
		{
			// Move to left side of node
			this.x = point.x - this.width - DisplayNode.radius - NODE_SPACING_LEFT - TIP_WIDTH;
			// Draw Tip
			this.graphics.moveTo(drawWidth, this.height / 2 - TIP_HEIGHT / 2);
			this.graphics.lineTo(drawWidth + TIP_WIDTH, this.height / 2);
			this.graphics.lineTo(drawWidth, this.height / 2 + TIP_HEIGHT / 2);
		}
		this.y = point.y - this.height / 2;
		this.graphics.endFill();
		// show
		this.visible = true;
	}
	public function hide():void
	{
		this.visible = false;
	}
}
}