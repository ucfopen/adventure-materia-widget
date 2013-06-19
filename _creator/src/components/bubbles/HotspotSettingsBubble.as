package components.bubbles {
	import components.DestinationBox;
	import components.HotspotImage;
	import components.ScoreBox;
	import components.SimpleDestinationBox;
import materia.Dialog;
import tree.DisplayNode;
	import tree.DisplayTree;
	import tree.Node;
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.DataEvent;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.ColorTransform;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFieldType;
	import flash.text.TextFormat;
	import mx.controls.CheckBox;
	import mx.controls.RadioButton;
	import mx.controls.TextArea;
	import mx.core.UIComponent;
	public class HotspotSettingsBubble extends AdventureBubble
	{
		//--------------------------------------------------------------------------
		//
		//  Class constants
		//
		//--------------------------------------------------------------------------
		private static const WIDTH:Number = 240;
		private static const HEIGHT_NORMAL:Number = 130;
		private static const HEIGHT_EXTENDED:Number = 160;
		private static const HEIGHT_EXTENDED_PLUS:Number = 330;
		private static const RADIO_HEIGHT:int = 10;
		private static const RADIO_WIDTH:int = 10;
		private static const INPUT_WIDTH:int = 50;
		private static const INPUT_HEIGHT:int = 24;
		private static const SPACING:int = 10;
		private static const INDENT:int = 10;
		private static const GROUP_1:String = "hotspot-visibility";
		private static const DESTINATION_RADIUS:int = 23;
		//--------------------------------------------------------------------------
		//
		//  Instance Variables
		//
		//--------------------------------------------------------------------------
		//----------------------------------
		//  References
		//----------------------------------
		private var _node:Node;
		private var _manager:HotspotImage;
		//----------------------------------
		//  Components
		//----------------------------------
		private var _groupLabel:TextField;
		private var _radio1:RadioButton;
		private var _label1:TextField;
		private var _radio2:RadioButton;
		private var _label2:TextField;
		private var _radio3:RadioButton;
		private var _label3:TextField;
		private var _destLabel:TextField;
		private var _destCheck:CheckBox;
		private var _destBox:DestinationBox;
		private var _scoreLabel:TextField;
		private var _scoreBoxContainer:UIComponent;
		private var _scoreBox:ScoreBox;
		private var _feedbackLabel:TextField;
		private var _feedbackArea:TextArea;
		private var _oldRadioSelected:int = -1;
		private var _newRadioSelected:int = -1;
		private var _lastSelected:Object;
		private var _isNew:Boolean = true;
		//--------------------------------------------------------------------------
		//
		//  Constructor
		//
		//--------------------------------------------------------------------------
		public function HotspotSettingsBubble(node:Node, manager:HotspotImage)
		{
			super(WIDTH, HEIGHT_NORMAL, "Image Hotspot Settings:");
			_node = node;
			_manager = manager;
			//----------------------------------
			//  Create Components
			//----------------------------------
			/* RadioGroup Label */
			_groupLabel = createLabel("For this image,", true);
			_groupLabel.x = PADDING;
			_groupLabel.y = _startY;
			this.addChild(_groupLabel);
			/* Radio 1 - Show hotspots for user */
			_radio1 = new RadioButton();
			_radio1.x = PADDING + INDENT;
			_radio1.y = _groupLabel.y + _groupLabel.height + SPACING;
			_radio1.groupName = GROUP_1;
			_radio1.addEventListener(MouseEvent.CLICK, onRadioClick, false, 0, true);
			_label1 = createLabel("Always show hotspots", false, true);
			_label1.x = _radio1.x + RADIO_WIDTH / 2 + PADDING;
			this.addChild(_radio1);
			_label1.y = _radio1.y - RADIO_HEIGHT;
			this.addChild(_label1);
			/* Radio 2 - Reveal hotspots on mouse over */
			_radio2 = new RadioButton();
			_radio2.x = PADDING + INDENT;
			_radio2.y = _radio1.y + RADIO_HEIGHT + SPACING;
			_radio2.groupName = GROUP_1;
			_radio2.addEventListener(MouseEvent.CLICK, onRadioClick, false, 0, true);
			_label2 = createLabel("Reveal hotspots on mouse over", false, true);
			_label2.x = _radio2.x + RADIO_WIDTH / 2 + PADDING;
			_label2.y = _radio2.y - RADIO_HEIGHT;
			this.addChild(_radio2);
			this.addChild(_label2);
			/* Radio 3 - Hide hotspots from user */
			_radio3 = new RadioButton();
			_radio3.x = PADDING + INDENT;
			_radio3.y = _radio2.y + RADIO_HEIGHT + SPACING;
			_radio3.groupName = GROUP_1;
			_radio3.addEventListener(MouseEvent.CLICK, onRadioClick, false, 0, true);
			_label3 = createLabel("Don't show hotspots", false, true);
			_label3.x = _radio3.x + RADIO_WIDTH / 2 + PADDING;
			_label3.y = _radio3.y - RADIO_HEIGHT;
			this.addChild(_radio3);
			this.addChild(_label3);
			/* Default Hotspot Choice */
			_destCheck = new CheckBox();
			_destCheck.x = PADDING;
			_destCheck.y = _radio3.y + RADIO_HEIGHT * 2 + SPACING;
			_destCheck.addEventListener(MouseEvent.CLICK, onCheckClick, false, 0, true);
			_destLabel = createLabel("Detect Background (Missed) Clicks", false);
			_destLabel.y =  _radio3.y + RADIO_HEIGHT + SPACING;
			_destLabel.x = _destCheck.x + RADIO_WIDTH + SPACING;
			_destLabel.visible = false;
			_destCheck.visible = false;
			this.addChild(_destCheck);
			this.addChild(_destLabel);
			/* Score Box for Default Hotspot Choice */
			_scoreLabel = createLabel("Score/Destination for Missed Clicks:", false);
			_scoreLabel.x = PADDING;
			_scoreLabel.y = _destLabel.y + _destLabel.height + SPACING;
			_scoreBoxContainer = new UIComponent();
			_scoreBoxContainer.width = ScoreBox.DEFAULT_WIDTH;
			_scoreBoxContainer.height = ScoreBox.DEFAULT_HEIGHT;
			_scoreBoxContainer.x = PADDING;
			_scoreBoxContainer.y = _scoreLabel.y + _scoreLabel.height;
			_scoreLabel.visible = false;
			_scoreBoxContainer.visible = false;
			this.addChild(_scoreLabel);
			this.addChild(_scoreBoxContainer);
			/* Destination Box */
			_destBox = new DestinationBox();
			_destBox.bubbleDirection = AdventureBubble.DIRECTION_LEFT;
			_destBox.width = DESTINATION_RADIUS * 2 + 10;
			_destBox.height = DESTINATION_RADIUS * 2 + 10;
			_destBox.x = _scoreBoxContainer.x + _scoreBoxContainer.width + PADDING;
			_destBox.y = _scoreBoxContainer.y;
			_destBox.addEventListener(DestinationBubble.EVENT_DESTINATION_CHOICE, onDestChange, false, 0, true);
			this.addChild(_destBox);
			_destBox.visible = false;
			/* Feedback Box */
			_feedbackLabel = createLabel("Feedback for Missed Clicks:", false);
			_feedbackLabel.x = PADDING;
			_feedbackLabel.y = _destBox.y + Math.max(_destBox.height, _scoreBoxContainer.height) + SPACING;
			_feedbackArea = new TextArea();
			_feedbackArea.addEventListener(Event.CHANGE, onFeedbackChange, false, 0, true);
			_feedbackArea.x = PADDING;
			_feedbackArea.y = _feedbackLabel.y + _feedbackLabel.height;
			_feedbackArea.width = WIDTH - PADDING * 2;
			_feedbackArea.height = 60;
			_feedbackLabel.visible = false;
			_feedbackArea.visible = false;
			this.addChild(_feedbackLabel);
			this.addChild(_feedbackArea);
			/* Set the Selected Option */
			if(_node.data.options.visibility != null)
			{
				_oldRadioSelected = _node.data.options.visibility;
				_newRadioSelected = _node.data.options.visibility;
				setSelected(_newRadioSelected);
			}
			/* Reset "New" Status */
			callLater(function t():void {
				_isNew = false;
			});
		}
		//--------------------------------------------------------------------------
		//
		//  Member Functions
		//
		//--------------------------------------------------------------------------
		public override function show(target:Sprite, direction:int = AdventureBubble.DIRECTION_UP, parent:DisplayObject = null):void
		{
			super.show(target, direction, parent);
		}
		public override function destroy():void
		{
			/* Update Visibility Settings */
			if(_radio1.selected) _node.data.options.visibility = AdventureOptions.VISIBILITY_ALWAYS;
			else if(_radio2.selected) _node.data.options.visibility = AdventureOptions.VISIBILITY_HOVER;
			else if(_radio3.selected) _node.data.options.visibility = AdventureOptions.VISIBILITY_NEVER;
			/* Remove Radio Label Listeners */
			_radio1.removeEventListener(MouseEvent.CLICK, onClickRadioLabel);
			_radio2.removeEventListener(MouseEvent.CLICK, onClickRadioLabel);
			_radio3.removeEventListener(MouseEvent.CLICK, onClickRadioLabel);
			/* Remove Listeners for Feedback */
			_feedbackArea.removeEventListener(Event.CHANGE, onFeedbackChange);
			super.destroy();
		}
		private function setSelected(radio:int):void
		{
			/* keep track of last radio selected (in case we want to revert) */
			if(radio != _oldRadioSelected)
			{
				_oldRadioSelected = _newRadioSelected;
				_newRadioSelected = radio;
			}
			/* simulate click event on desired radio event */
			var evt:MouseEvent = new MouseEvent(MouseEvent.CLICK);
			switch(radio)
			{
				case 0:
					_radio1.dispatchEvent(evt);
					break;
				case 1:
					_radio2.dispatchEvent(evt);
					break;
				case 2:
					_radio3.dispatchEvent(evt);
					break;
				default:
					break;
			}
		}
		private function revertSelection():void
		{
			var newRadio:int = _oldRadioSelected;
			_oldRadioSelected = -1;
			setSelected(newRadio);
		}
		private function onClickRadioLabel(e:MouseEvent):void
		{
			var evt:MouseEvent = new MouseEvent(MouseEvent.CLICK);
			switch(e.target)
			{
				case _label1:
					_radio1.dispatchEvent(evt);
					break;
				case _label2:
					_radio2.dispatchEvent(evt);
					break;
				case _label3:
					_radio3.dispatchEvent(evt);
					break;
				default:
					break;
			}
		}
		private function onFeedbackChange(e:Event):void
		{
			_node.data.answers[0].options.feedback = _feedbackArea.text;
		}
		private function createLabel(text:String, bold:Boolean = false, clickListener:Boolean = false):TextField
		{
			var result:TextField = new TextField();
			result.selectable = false;
			result.defaultTextFormat = new TextFormat(null, 14, 0x0, bold);
			result.text = text;
			result.autoSize = TextFieldAutoSize.LEFT;
			if(clickListener) result.addEventListener(MouseEvent.CLICK, onClickRadioLabel, false, 0, true);
			return result;
		}
		private function setScoreBoxEnabled(value:Boolean):void
		{
			// Disabled for Destination mode.
			return;
			/* Ignore if setting to an existing value */
			// TODO: Update to check participationMode
			/*
			if(displayTree.scoreStyle == AdventureOptions.SCORESTYLE_DESTINATION) return;
			if(value == (_scoreBox != null)) return;
			if(value)
			{
				/* update visibility */
				/*
				_scoreLabel.visible = true;
				_feedbackLabel.visible = true;
				_feedbackArea.visible = true;
				*/
				/* update feedback area contents */
				/*
				if(_node.data.answers[0].options.feedback)
				{
					_feedbackArea.text = _node.data.answers[0].options.feedback;
				}
				*/
				/* Otherwise, if answer area carries content, save it */
				/*
				else if(_feedbackArea.text)
				{
					_node.data.answers[0].options.feedback = _feedbackArea.text;
				}
				*/
				/* update scorebox */
				/*
				_scoreBox = new ScoreBox();
				_scoreBox.hostNode = _node;
				_scoreBox.targetAnswer = 0;
				_scoreBox.setStyle("backgroundColor", 0xffffff);
				_scoreBox.setStyle("borderStyle", "solid");
				_scoreBox.setStyle("borderThickness", 1);
				_scoreBox.setStyle("borderColor", 0xcccccc);
				_scoreBoxContainer.addChild(_scoreBox);
				changeHeight(HEIGHT_EXTENDED_PLUS);
			}
			else
			{
				_scoreLabel.visible = false;
				_feedbackLabel.visible = false;
				_feedbackArea.visible = false;
				_scoreBox.destroy();
				_scoreBoxContainer.removeChild(_scoreBox);
				_scoreBox = null;
			}
			*/
		}
		private function onRadioClick(e:Event):void
		{
			if(e.target == _lastSelected) return;
			_lastSelected = e.target;
			if(e.target == _radio3) showDefaultHotspotOption();
			else hideDefaultHotspotOption();
		}
		private function onCheckClick(e:Event):void
		{
			if(_destCheck.selected) enableDefaultHotspot();
			else disableDefaultHotspot();
		}
		private function showDefaultHotspotOption():void
		{
			/* show the default hotspot components */
			_destCheck.visible = true;
			_destLabel.visible = true;
			_destBox.visible = true;
			_scoreBoxContainer.visible = true;
			/* make this bubble bigger to fit all the stuff */
			changeHeight(HEIGHT_EXTENDED);
			if(!_isNew || _node.data.answers.length && _node.data.answers[0].options.isDefault) enableDefaultHotspot();
		}
		private function hideDefaultHotspotOption():void
		{
			/* hide the default hotspot components */
			_destCheck.visible = false;
			_destLabel.visible = false;
			_destBox.visible = false;
			_scoreBoxContainer.visible = false;
			disableDefaultHotspot();
			/* bring the bubble back to its normal height */
			changeHeight(HEIGHT_NORMAL);
		}
		private function enableDefaultHotspot():void
		{
			_destBox.visible = true;
			_destCheck.selected = true;
			/* only create the default answer if it doesn't already exist */
			if(!_node.data.answers.length || !_node.data.answers[0].options.isDefault)
			{
				/* add the child node and related answer */
				var newNode:Node = addNode(_node);
				_node.data.addAnswer("Missed (Default) Hotspot", "100", { isDefault:true });
				/* move the node and related answer to the beginning */
				var tempNode:Node = _node.children.pop();
				if(tempNode.leftSibling) tempNode.leftSibling.rightSibling = tempNode.rightSibling;
				tempNode.leftSibling = null;
				tempNode.rightSibling = _node.children.length ? _node.children[0] : null;
				if(tempNode.rightSibling) tempNode.rightSibling.leftSibling = tempNode;
				_node.children.splice(0, 0, newNode);
				var tempAns:Object = _node.data.answers[_node.data.answers.length - 1];
				tempAns.options.link = newNode.id;
				_node.data.answers.pop();
				_node.data.answers.splice(0, 0, tempAns);
			}
			/* set contents for new destination box */
			updateDestinationBox();
			/* enable the score box */
			setScoreBoxEnabled(true);
		}
		private function updateDestinationBox():void
		{
			_destBox.setTargetNode(_node.children[0], DESTINATION_RADIUS);
		}
		private function disableDefaultHotspot():void
		{
			_destBox.visible = false;
			/* make sure the default hotspot exists before deleting it */
			if(!_node.data.answers.length || !_node.data.answers[0].options.isDefault) return;
			/* make sure default node doesn't have children */
			if(_node.children[0].children.length)
			{
				revertSelection();
				Dialog.show(Dialog.OK, "Cannot Delete Default Hotspot", "Changing this setting will result in the deletion of the default hotspot destination and all of it's children. Please make sure the default destination has no children before changing this setting.");
				return;
			}
			var deleteTarget:Node = _node.children[0];
			/* request to delete the default hotspot and related answer */
			if(!displayTree.attemptDeleteNode(deleteTarget, false))
			{
				/* if we can't delete the child node, re-enable default hotspot */
				revertSelection();
				return;
			}
			/* otherwise, if delete succeeded: */
			else
			{
				/* if node had content, path was not removed. remove path */
				if(_node.children.length && deleteTarget == _node.children[0])
				{
					displayTree.attemptDeleteNode(deleteTarget, false);
				}
			}
			/* disable the score box */
			setScoreBoxEnabled(false);
			changeHeight(HEIGHT_EXTENDED);
		}
		/**
		 * Changes the height of the bubble and adjusts position accordingly
		 */
		private function changeHeight(newHeight:Number):void
		{
			var heightDiff:int = newHeight - _height;
			_height = newHeight;
			switch(direction)
			{
				case DIRECTION_UP:
					this.y -= heightDiff;
					break;
				case DIRECTION_LEFT:
				case DIRECTION_RIGHT:
					this.y -= heightDiff / 2;
					break;
			}
			this.graphics.clear();
			drawBubble();
		}
		private function onDestChange(e:DataEvent):void
		{
			/* make sure default destination exists */
			if(!_node.data.answers.length || !_node.data.answers[0].options.isDefault) return;
			/* set the new default destination */
			var result:int = int(e.data);
			switch(result)
			{
				case DestinationBubble.THIS_NODE:
					displayTree.setLink(_node.children[0], _node);
					break;
				case DestinationBubble.NEW_NODE:
					displayTree.setLink(_node.children[0], _node.children[0]);
					break;
				case DestinationBubble.EXISTING_NODE:
					_manager.dispatchEvent(new DataEvent(DisplayNode.EVENT_FIND_LINK, true, false, String(_node.children[0].id)));
					destroy();
					return;
			}
			/* set contents for destination box */
			updateDestinationBox();
		}
		private function get displayTree():DisplayTree
		{
			return _node.displayNode.displayTree;
		}
		private function addNode(parentNode:Node):Node
		{
			return parentNode.displayNode.displayTree.addNode(parentNode, null).node;
		}
	}
}