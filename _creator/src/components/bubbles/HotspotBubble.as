package components.bubbles {
	import components.DestinationBox;
	import components.ScoreBox;
	import components.SimpleDestinationBox;
	import events.HotspotArrangementEvent;
	import tree.DisplayNode;
	import tree.Node;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.events.DataEvent;
	import flash.events.Event;
	import flash.events.IEventDispatcher;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFieldType;
	import flash.text.TextFormat;
	import mx.controls.Button;
	import mx.core.UIComponent;
	import hotspots.AdventureDisplayHotspot;
	import hotspots.AdventureHotspotPolygon;
	public class HotspotBubble extends AdventureBubble
	{
		public static const EVENT_DELETE:String = "hotspot-delete";
		public static const EVENT_REDRAW:String = "hotspot-redraw";
		[Embed (source="../../assets/layer-up.png")]
		private static const ICON_LAYER_UP:Class;
		[Embed (source="../../assets/layer-down.png")]
		private static const ICON_LAYER_DOWN:Class;
		public static const WIDTH:Number = 330;
		public static const HEIGHT:Number = 325;
		private static const COLUMN1_WIDTH:Number = 200;
		private static const ICON_BUTTON_WIDTH:Number = 40;
		private static const BUTTON_WIDTH:Number = 70;
		private static const BUTTON_HEIGHT:Number = 26;
		private static const INPUT_HEIGHT:int = 25;
		private static const INPUT_AREA_HEIGHT:int = 80;
		private static const DESTINATION_RADIUS:int = 23;
		public static const SPACING:int = 5;
		private static const COLUMN_SPACING:int = 15;
		//----------------------------------
		//  References
		//----------------------------------
		public var node:Node;
		public var destroyed:Boolean = false;
		private var _hotspot:AdventureDisplayHotspot;
		private var _container:DisplayObjectContainer;
		//----------------------------------
		//  Components
		//----------------------------------
		private var _destinationBubble:DestinationBubble;
		private var _labelLabel:TextField;
		private var _labelInput:TextField;
		private var _feedbackLabel:TextField;
		private var _feedbackInput:TextField;
		private var _destinationLabel:TextField;
		private var _destinationBox:DestinationBox;
		private var _scoreLabel:TextField;
		private var _scoreBox:ScoreBox;
		private var _arrangementLabel:TextField;
		private var _layerButtonUp:Button;
		private var _layerButtonDown:Button;
		private var _redrawButton:Button;
		private var _deleteButton:Button;
		private var _doneButton:Button;
		public function HotspotBubble(node:Node, hotspot:AdventureDisplayHotspot, container:DisplayObjectContainer)
		{
			super(WIDTH, HEIGHT, "Hotspot:");
			this.hotspot = hotspot;
			this.node = node;
			_container = container;
			//----------------------------------
			//  Create Components
			//----------------------------------
			/* Label Label & Input */
			_labelLabel = createLabel("Label:");
			_labelLabel.x = PADDING;
			_labelLabel.y = _startY;
			this.addChild(_labelLabel);
			_labelInput = createInput();
			_labelInput.x = PADDING;
			_labelInput.y = _labelLabel.y + _labelLabel.height + SPACING;
			_labelInput.width = COLUMN1_WIDTH;
			_labelInput.height = INPUT_HEIGHT;
			this.addChild(_labelInput);
			/* Feedback Label & Input */
			_feedbackLabel = createLabel("Feedback:");
			_feedbackLabel.x = PADDING;
			_feedbackLabel.y = _labelInput.y + INPUT_HEIGHT + SPACING * 2;
			this.addChild(_feedbackLabel);
			_feedbackInput = createInput();
			_feedbackInput.x = PADDING;
			_feedbackInput.y = _feedbackLabel.y + _feedbackLabel.height + SPACING;
			_feedbackInput.multiline = true;
			_feedbackInput.wordWrap = true;
			_feedbackInput.width = COLUMN1_WIDTH;
			_feedbackInput.height = INPUT_AREA_HEIGHT;
			this.addChild(_feedbackInput);
			/* Arrangement Label & Buttons */
			_arrangementLabel = createLabel("Arrangement:");
			_arrangementLabel.x = PADDING;
			_arrangementLabel.y = _feedbackInput.y + INPUT_AREA_HEIGHT + SPACING * 2;
			this.addChild(_arrangementLabel);
			_layerButtonUp = createButton("");
			_layerButtonUp.toolTip = "Move this hotspot up one layer";
			_layerButtonUp.width = ICON_BUTTON_WIDTH;
			_layerButtonUp.setStyle("icon", ICON_LAYER_UP);
			_layerButtonUp.x = PADDING;
			_layerButtonUp.y = _arrangementLabel.y + _arrangementLabel.height + SPACING;
			_layerButtonUp.addEventListener(MouseEvent.CLICK, onLayerUpClick, false, 0, true);
			this.addChild(_layerButtonUp);
			_layerButtonDown = createButton("");
			_layerButtonDown.toolTip = "Move this hotspot down one layer";
			_layerButtonDown.width = ICON_BUTTON_WIDTH;
			_layerButtonDown.setStyle("icon", ICON_LAYER_DOWN);
			_layerButtonDown.x = _layerButtonUp.x + _layerButtonUp.width + SPACING;
			_layerButtonDown.y = _layerButtonUp.y;
			_layerButtonDown.addEventListener(MouseEvent.CLICK, onLayerDownClick, false, 0, true);
			this.addChild(_layerButtonDown);
			/* Destination Label & Input */
			_destinationLabel = createLabel("Destination:");
			_destinationLabel.x = PADDING + COLUMN1_WIDTH + COLUMN_SPACING;
			_destinationLabel.y = _startY;
			this.addChild(_destinationLabel);
			_destinationBox = new DestinationBox();
			_destinationBox.bubbleDirection = AdventureBubble.DIRECTION_LEFT;
			_destinationBox.width = DESTINATION_RADIUS * 2 + 10;
			_destinationBox.height = DESTINATION_RADIUS * 2 + 10;
			_destinationBox.x = PADDING + COLUMN1_WIDTH + COLUMN_SPACING;
			_destinationBox.y = _destinationLabel.y + _destinationLabel.height + SPACING;
			this.addChild(_destinationBox);
			/* Score Label & Box */
			// TODO: Update this with ParticipationMode.
			/*
			if(node.displayNode.displayTree.scoreStyle != AdventureOptions.SCORESTYLE_DESTINATION)
			{
				_scoreLabel = createLabel("Score:");
				_scoreLabel.x = PADDING + COLUMN1_WIDTH + COLUMN_SPACING;
				_scoreLabel.y = _destinationBox.y + _destinationBox.height + SPACING * 2;
				this.addChild(_scoreLabel);
				_scoreBox = new ScoreBox();
				_scoreBox.scoreStyle = node.displayNode.displayTree.scoreStyle;
				_scoreBox.setStyle("backgroundColor", 0xffffff);
				_scoreBox.setStyle("borderStyle", "solid");
				_scoreBox.setStyle("borderThickness", 1);
				_scoreBox.setStyle("borderColor", 0xcccccc);
				_scoreBox.hostNode = node;
				_scoreBox.targetAnswer = _hotspot.id + (hasDefault ? 1 : 0);
				_scoreBox.x = PADDING + COLUMN1_WIDTH + COLUMN_SPACING;
				_scoreBox.y = _scoreLabel.y + _scoreLabel.height;
				this.addChild(_scoreBox);
			}
			*/
			/* Redraw Button */
			_redrawButton = createButton("Redraw");
			_redrawButton.x = PADDING;
			_redrawButton.y = HEIGHT - POINTER_HEIGHT - BUTTON_HEIGHT - PADDING;
			_redrawButton.addEventListener(MouseEvent.CLICK, onRedrawClick, false, 0, true);
			this.addChild(_redrawButton);
			/* Delete Button */
			if(!node.children[hotspot.id + (hasDefault ? 1 : 0)].children.length)
			{
				_deleteButton = createButton("Delete");
				_deleteButton.x = _redrawButton.x + BUTTON_WIDTH + SPACING;
				_deleteButton.y = _redrawButton.y;
				_deleteButton.addEventListener(MouseEvent.CLICK, onDeleteClick, false, 0, true);
				this.addChild(_deleteButton);
			}
			/* Done Button */
			_doneButton = createButton("Done");
			_doneButton.x = WIDTH - PADDING - BUTTON_WIDTH;
			_doneButton.y = _redrawButton.y;
			_doneButton.addEventListener(MouseEvent.CLICK, onDoneClick, false, 0, true);
			this.addChild(_doneButton);
			/* Load info into the input fields */
			var index:int = hotspot.id + (hasDefault ? 1 : 0);
			_destinationBox.setTargetNode(node.children[index], DESTINATION_RADIUS);
			if(node.data.answers[index].text) _labelInput.text = node.data.answers[hotspot.id + (hasDefault ? 1 : 0)].text;
			if(node.data.answers[index].options.feedback) _feedbackInput.text = node.data.answers[hotspot.id + (hasDefault ? 1 : 0)].options.feedback;
		}
		protected override function onClickApplication(e:Event):void
		{
			/* Don't destroy this bubble when clicking on destination bubble */
			var target:Object = e.target;
			while(target != null)
			{
				if(target == _destinationBubble) return;
				target = target.parent;
			}
			/* Destroy this bubble when clicking anywhere else */
			super.onClickApplication(e);
			save();
		}
		protected function updateDestinationBox():void
		{
			if(_destinationBox != null)
			{
				_destinationBox.setTargetNode(this.node);
			}
		}
		public function get hotspot():AdventureDisplayHotspot { return _hotspot; }
		public function set hotspot(val:AdventureDisplayHotspot):void
		{
			if(val == _hotspot) return;
			// Dispose of old hotspot
			if(_hotspot != null)
			{
				_hotspot.selected = false;
				hotspot.removeEventListener(AdventureDisplayHotspot.EVENT_DRAG_BEGIN, onHotspotDragBegin);
				hotspot.removeEventListener(AdventureDisplayHotspot.EVENT_DRAG_END, onHotspotDragEnd);
			}
			// Add new hotspot
			_hotspot = val;
			_hotspot.selected = true;
			hotspot.addEventListener(AdventureDisplayHotspot.EVENT_DRAG_BEGIN, onHotspotDragBegin, false, 0, true);
			hotspot.addEventListener(AdventureDisplayHotspot.EVENT_DRAG_END, onHotspotDragEnd, false, 0, true);
		}
		public override function show(target:Sprite, direction:int = AdventureBubble.DIRECTION_UP, parent:DisplayObject = null):void
		{
			hotspot = AdventureDisplayHotspot(target);
			super.show(target, direction, parent);
			/* Draw Divider Line Above Redraw Button */
			this.graphics.lineStyle(1, 0xbbbbbb);
			this.graphics.moveTo(PADDING, _redrawButton.y - SPACING);
			this.graphics.lineTo(WIDTH - PADDING, _redrawButton.y - SPACING);
			_destinationBox.addEventListener(DestinationBubble.EVENT_DESTINATION_CHOICE, onDestChange, false, 0, true);
		}
		public override function updatePosition(target:Sprite):void
		{
			super.updatePosition(target);
			var containerPoint:Point = _container.localToGlobal(new Point(_container.x, _container.y));
		}
		public function save():void
		{
			node.data.answers[hotspot.id + (hasDefault ? 1 : 0)].text = _labelInput.text;
			node.data.answers[hotspot.id + (hasDefault ? 1 : 0)].options.feedback = _feedbackInput.text;
		}
		/**
		 * Destroys this hotspot bubble but saves its data to the attached hotspot
		 */
		public function destroySave():void
		{
			destroy();
			save();
		}
		/**
		 * Destroys this hotspot bubble and removes all listeners
		 */
		public override function destroy():void
		{
			super.destroy();
			_destinationBox.removeEventListener(DestinationBubble.EVENT_DESTINATION_CHOICE, onDestChange);
			if(_hotspot != null)
			{
				_hotspot.selected = false;
				_hotspot.removeEventListener(AdventureDisplayHotspot.EVENT_DRAG_BEGIN, onHotspotDragBegin);
				_hotspot.removeEventListener(AdventureDisplayHotspot.EVENT_DRAG_END, onHotspotDragEnd);
			}
			_doneButton.removeEventListener(MouseEvent.CLICK, onDoneClick);
			this.destroyed = true;
		}
		/**
		 * Sets focus to and selects the label input
		 */
		public function setLabelFocus():void
		{
			_labelInput.setSelection(0, _labelInput.text.length);
			stage.focus = _labelInput;
		}
		private function onLayerDownClick(e:Event):void
		{
			this.dispatchEvent(new HotspotArrangementEvent(HotspotArrangementEvent.ARRANGE_DOWN, hotspot));
		}
		private function onLayerUpClick(e:Event):void
		{
			this.dispatchEvent(new HotspotArrangementEvent(HotspotArrangementEvent.ARRANGE_UP, hotspot));
		}
		private function onRedrawClick(e:MouseEvent):void
		{
			dispatchEvent(new Event(EVENT_REDRAW));;
		}
		private function onDoneClick(e:MouseEvent):void
		{
			destroySave();
		}
		private function onDeleteClick(e:MouseEvent):void
		{
			dispatchEvent(new Event(EVENT_DELETE));;
		}
		private function onDestChange(e:DataEvent):void
		{
			var result:int = int(e.data);
			switch(result) {
				case DestinationBubble.THIS_NODE:
					node.displayNode.displayTree.setLink(node.children[hotspot.id + (hasDefault ? 1 : 0)], node);
					break;
				case DestinationBubble.NEW_NODE:
					node.displayNode.displayTree.setLink(node.children[hotspot.id + (hasDefault ? 1 : 0)], node.children[hotspot.id + (hasDefault ? 1 : 0)]);
					break;
				case DestinationBubble.EXISTING_NODE:
					hotspot.dispatchEvent(new DataEvent(DisplayNode.EVENT_FIND_LINK, true, false, String(node.children[hotspot.id + (hasDefault ? 1 : 0)].id)));
					destroySave();
					break;
			}
			var link:String = node.data.answers[hotspot.id + (hasDefault ? 1 : 0)].options.link;
			_destinationBox.redraw();
//			if(link != null) _destinationBox.text = DisplayNode.idToLabel(int(link));
		}
		private function createLabel(text:String):TextField
		{
			var result:TextField = new TextField();
			result.selectable = false;
			result.defaultTextFormat = new TextFormat("Arial", 14, 0x0, true);
			result.text = text;
			result.autoSize = TextFieldAutoSize.LEFT;
			return result;
		}
		private function createInput():TextField
		{
			var result:TextField = new TextField();
			result.type = TextFieldType.INPUT;
			result.background = true;
			result.backgroundColor = 0xffffff;
			result.border = true;
			result.borderColor = 0xcccccc;
			result.defaultTextFormat = new TextFormat("Arial", 14, 0x0, true);
			return result;
		}
		private function createButton(text:String):Button
		{
			var result:Button = new Button;
			result = new Button();
			result.setStyle("paddingRight", "0");
			result.setStyle("paddingLeft", "0");
			result.label = text;
			result.width = BUTTON_WIDTH;
			result.height = BUTTON_HEIGHT;
			return result;
		}
		private function onHotspotDragBegin(e:Event):void
		{
			this.visible = false;
		}
		private function onHotspotDragEnd(e:Event):void
		{
			updatePosition(hotspot);
			save();
			this.visible = true;
			// protect from self destroy
			_mouseWasInside = true;
		}
		private function get hasDefault():Boolean
		{
			return node.data.answers.length && node.data.answers[0].options.isDefault;
		}
	}
}