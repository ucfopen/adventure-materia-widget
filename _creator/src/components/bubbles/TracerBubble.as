package components.bubbles {
import tree.DisplayNode;
import tree.Node;
import flash.display.Sprite;
import flash.geom.Point;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFormat;
public class TracerBubble extends Sprite
{
	private static const FORMAT_TRACER:TextFormat = new TextFormat("Arial", 12, 0xb2b2b2, true);
	private static const FORMAT_LABEL:TextFormat = new TextFormat("Arial", 12, 0xffffff, false);
	private static const COLOR_BG:Number = 0x919191;
	private static const NODE_SPACING_RIGHT:Number = 16;
	private static const NODE_SPACING_LEFT:Number = 10;
	private static const VERTICAL_GAP:Number = 5;
	private static const PADDING_V:Number = 5;
	private static const PADDING_H:Number = 10;
	private static const MAX_CHARS:Number = 30;
	private static const MAX_LINES:Number = 3;
	private static const CORNER_RADIUS:Number = 10;
	private static const DEFAULT_ANSWER_TEXT:String = "[No Text For Answer]";
	private var _tracerTf:TextField;
	private var _questionTf:TextField;
	public function TracerBubble()
	{
		_tracerTf = new TextField();
		_tracerTf.selectable = false;
		_tracerTf.autoSize = TextFieldAutoSize.LEFT;
		_tracerTf.defaultTextFormat = FORMAT_TRACER;
		_tracerTf.text = "Tracer";
		this.addChild(_tracerTf);
		_questionTf = new TextField();
		_questionTf.selectable = false;
		_questionTf.autoSize = TextFieldAutoSize.LEFT;
		_questionTf.defaultTextFormat = FORMAT_LABEL;
		_questionTf.x = PADDING_H;
		_questionTf.y = _tracerTf.height + VERTICAL_GAP + PADDING_V;
		this.addChild(_questionTf);
	}
	public function show(node:Node):void
	{
		this.graphics.clear();
		var target:Node = node.parent;
		var id:int = node.isShortcut ? node.shortcut : node.id;
		_tracerTf.text = "Answer from '" + DisplayNode.idToLabel(target.id) + "' that leads to '" + DisplayNode.idToLabel(id) + "'";
		// Get question from target that leads to given node
		var i:int;
		var answerText:String;
		for(i = 0; i < target.children.length; i++)
		{
			if(target.children[i] == node)
			{
				answerText = target.data.answers[i].text;
				break;
			}
		}
		// Limit max newlines
		var temp:String = answerText;
		var cutIndex:int = -1;
		for(i = 0; i < MAX_LINES; i++)
		{
			var cut:int = temp.search(new RegExp("\n\r|\n|\r"));
			if(cut != -1) {
				temp = temp.substring(cut + 1);
				cutIndex += cut + 1; }
			else { cutIndex = -1; break; }
		}
		if(cutIndex != -1) answerText = answerText.substr(0, cutIndex) + " ...";
		// Limit max characters
		if(answerText.length > MAX_CHARS) answerText = answerText.substr(0, MAX_CHARS) + " ...";
		// Put newly filtered text into the field
		_questionTf.text = answerText.length ? answerText : DEFAULT_ANSWER_TEXT;
		var tfW:int = _questionTf.width + PADDING_H * 2;
		var tfH:int = _questionTf.height + PADDING_V * 2;
		var tfX:int;
		// Set Position
		var targetPoint:Point = this.parent.globalToLocal(target.displayNode.parent.localToGlobal(new Point(target.displayNode.x, target.displayNode.y)));
		this.y = targetPoint.y - this.height / 2;
		if(targetPoint.x < target.displayNode.displayTree.width / 2 && target.parent != null)
		{
			// Move TO RIGHT of target if target is towards the left
			tfX = 0;
			_questionTf.x = tfX + PADDING_H;
			this.x = targetPoint.x + DisplayNode.radius + NODE_SPACING_RIGHT;
		}
		else
		{
			// Move TO LEFT of target if target is towads the right (or if target is start node)
			tfX = _tracerTf.textWidth - _questionTf.width - PADDING_H * 2;
			_questionTf.x = tfX + PADDING_H;
			this.x = targetPoint.x - DisplayNode.radius - this.width - NODE_SPACING_LEFT;
		}
		// Draw Background
		this.graphics.beginFill(COLOR_BG);
		this.graphics.drawRoundRect(tfX, _questionTf.y - PADDING_V, tfW, tfH, CORNER_RADIUS);
		// Show!
		this.visible = true;
	}
	public function hide():void
	{
		this.visible = false;
	}
}
}