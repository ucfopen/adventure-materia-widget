/* See the file "LICENSE.txt" for the full license governing this code. */
package {
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.DisplayObject;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import flash.filters.GlowFilter;
import flash.geom.Rectangle;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFieldType;
import flash.text.TextFormat;
import flash.ui.Keyboard;

import hotspots.AdventureDisplayHotspot;
import hotspots.AdventureHotspot;
import hotspots.AdventureHotspotEllipse;
import hotspots.AdventureHotspotPolygon;
import hotspots.AdventureHotspotRect;

import nm.gameServ.common.Question;
import nm.gameServ.common.QuestionGroup;
import nm.gameServ.engines.EngineCore;
import nm.geom.Dimension;
import nm.ui.ScrollClip;
import nm.ui.ScrollText;
import nm.ui.ToolTip;
/**
 * Main class for Choose Your Own Adventure
 */
public class Engine extends EngineCore
{
	//--------------------------------------------------------------------------
	//
	//  Embedded Objects
	//
	//--------------------------------------------------------------------------
	//----------------------------------
	//  Fonts
	//----------------------------------
	// for embedded fonts to work in flex 4.1 framework, add: embedAsCFF="false"
    [Embed(source="/assets/fonts/ClassicRound.ttf", fontFamily="ClassicRound", unicodeRange='U+0041-U+005A, U+0061-U+007A, U+0021-U+0021, U+003A-U+003A, U+0028-U+0039')]
	public static const classicRoundFont:Class;
	//----------------------------------
	//  Images
	//----------------------------------
	[Embed (source="/assets/icons/hotspot.png")]
	public static const ICON_HOTSPOT:Class;
	[Embed (source="/assets/icons/mc.png")]
	public static const ICON_MC:Class;
	[Embed (source="/assets/icons/narration.png")]
	public static const ICON_NARRATION:Class;
	[Embed (source="/assets/icons/shortanswer.png")]
	public static const ICON_SHORTANS:Class;
	//--------------------------------------------------------------------------
	//
	//  Constants
	//
	//--------------------------------------------------------------------------
	private static const PADDING_TEXT:Number = 10;
	private static const PADDING_V:Number = 20;
	private static const PADDING_H:Number = 20;
	private static const PADDING_ASSET:Number = 10;
	private static const QUESTION_FIELD_OFFSET_Y:Number = -6;
	private static const ICON_SIZE:Number = 65;
	private static const SCORE_SCREEN_ID:int = -1;
	private static const DEFAULT_TEXT_END:String = "You have reached the end of this adventure. Click the button below to view your score.";
	private static const DEFAULT_TEXT_START:String = "Click on the button below to begin your adventure.";
	//----------------------------------
	//  Main Colors
	//----------------------------------
	public static const COLOR_BG:Number = 0xf9f8f9;
	public static const COLOR_BOX_BG:Number = 0xffffff;
	public static const COLOR_LABEL_BG:Number = 0xfef6b1;
	public static const COLOR_GRID:Number = 0xe3e3e3;
	public static const COLOR_ACCENT_1:Number = 0x7299b5;
	public static const COLOR_TEXT_1:Number = 0xffffff;
	public static const COLOR_TEXT_2:Number = 0xd1e2ee;
	public static const COLOR_TEXT_MAIN:Number = 0x575757;
	public static const COLOR_INFO_BAR_BORDER_1:Number = 0x9db8cb;
	public static const COLOR_INFO_BAR_BORDER_2:Number = 0x5b7a91;
	public static const COLOR_INFO_BAR_BORDER_3:Number = 0xcccccc;
	public static const COLOR_BOX_BORDER:Number = 0xcccccc;
	public static const COLOR_INFO_BAR_UNDERLINE:Number = 0xb9ccda;
	//----------------------------------
	//  Grid
	//----------------------------------
	public static const GRID_WIDTH:Number = 30;
	public static const GRID_HEIGHT:Number = 30;
	public static const GRID_SPACING:Number = 2; // should be a denominator of GRID_WIDTH & GRID_HEIGHT
	//----------------------------------
	//  Info Bar
	//----------------------------------
	public static const INFO_BAR_HEIGHT:Number = 46;
	public static const INFO_BAR_PADDING_H:Number = 10;
	public static const INFO_BAR_PADDING_V:Number = 10;
	//----------------------------------
	//  Feedback Box
	//----------------------------------
	public static const FEEDBACK_MODAL_COLOR:Number = 0x333333;
	public static const FEEDBACK_MODAL_ALPHA:Number = .3;
	public static const FEEDBACK_BORDER_STROKE:Number = 5;
	public static const FEEDBACK_BORDER_COLOR:Number = 0x999999;
	//----------------------------------
	//  Buttons
	//----------------------------------
	public static const BUTTON_WIDTH_MIN:Number = 150;
	public static const BUTTON_WIDTH_MAX:Number = 300;
	public static const BUTTON_HEIGHT:Number = 50
	public static const BUTTON_PADDING_V:Number = 5;
	public static const BUTTON_PADDING_H:Number = 10;
	//----------------------------------
	//  Text Formats
	//----------------------------------
	public static const FORMAT_TITLE:TextFormat = new TextFormat("ClassicRound", 30, COLOR_TEXT_1, true);
	public static const FORMAT_SHORT_ANSWER:TextFormat = new TextFormat("ClassicRound", 30, COLOR_TEXT_MAIN, true);
	public static const FORMAT_QUESTION:TextFormat = new TextFormat("ClassicRound", 30, COLOR_TEXT_MAIN, true);
	public static const FORMAT_CHOICE:TextFormat = new TextFormat("ClassicRound", 20, COLOR_TEXT_MAIN, true);
	public static const FORMAT_LABEL:TextFormat = new TextFormat("ClassicRound", 14, COLOR_TEXT_MAIN, false);
	//----------------------------------
	//  Filter Sets
	//----------------------------------
	public static const FILTERSET_CHOICE:Array = [new GlowFilter(0x00ff00, 1, 2, 2, 1)];
	//----------------------------------
	//  Layouts
	//----------------------------------
	public static const DIM_QUESTION_HOTSPOT:Dimension = new Dimension(600, 110);
	public static const DIM_FEEDBACK:Dimension = new Dimension(600, 300);
	//----------------------------------
	//  Positions
	//----------------------------------
	public static const POSITION_LEFT:int = 0;
	public static const POSITION_TOP:int = 1;
	public static const POSITION_RIGHT:int = 2;
	public static const POSITION_BOTTOM:int = 3;
	public static const POSITION_CENTER:int = 4;
	//--------------------------------------------------------------------------
	//
	//  Instance Variables
	//
	//--------------------------------------------------------------------------
	private var _stageDim:Dimension;
	private var _mainCanvasDim:Dimension;
	/**
	 * The main qGroup in the Question Set
	 */
	private var _mGroup:QuestionGroup;
	private var _currentNode:Object;
	private var _typeIconIncluded:Boolean = false;
	private var _typeIcon:Bitmap;
	private var _horizDim:Dimension;
	private var _vertDim:Dimension;
	private var _hotspotDefaultAnswer:Object;
	// private var _scoreStyle:int;
	private var _scoreQIDs:Array;
	private var _scoreSelectedAnswers:Array;
	private var _selectedFinalAnswer:String; // Replaces _scoreDeferredAnswers, this is the final answer from the selected end node.
	private var _scoreSelectedAnswerIds:Array;

	//----------------------------------
	//  Components
	//----------------------------------
	private var _questionBox:Sprite;
	private var _questionField:ScrollText;
	private var _questionBoxDim:Dimension
	private var _assetBox:Sprite;
	private var _assetBoxDim:Dimension;
	private var _answerBoxContainer:ScrollClip;
	private var _answerBox:Sprite;
	private var _answerBoxDim:Dimension;
	private var _shortAnswerBox:Sprite;
	private var _shortAnswerButton:AdventureButton;
	private var _shortAnswerField:TextField;
	private var _shortAnswerDim:Dimension;
	private var _infoBar:Sprite;
	private var _infoBarDim:Dimension;
	private var _titleField:TextField;
	private var _continueButton:AdventureButton;
	private var _continueButtonText:TextField;
	private var _buttonTarget:int;             // ID of the node button is linked to
	private var _hotspotBox:Sprite;
	private var _hotspotBoxDim:Dimension;
	private var _feedbackBox:Sprite;
	private var _feedbackBoxDim:Dimension;
	private var _feedbackBoxText:ScrollText;
	private var _feedbackButton:AdventureButton;
	private var _feedbackModal:Sprite;
	private var _bgBox:Sprite;
	private var _bgBoxDim:Dimension;
	//--------------------------------------------------------------------------
	//
	//  Functions
	//
	//--------------------------------------------------------------------------
	/**
	 * Function called when the engine is first started.
	 * initiates and creates everything. serves as a constructor
	 */
	protected override function startEngine():void
	{
		super.startEngine();
		var qq:* = EngineCore.qSetData;
		_mGroup = QuestionGroup.convertObject(EngineCore.qSetData.items[0]);
		//_scoreStyle = _mGroup.options.scoreStyle;
		initUI();
		loadNode(0);

		_scoreSelectedAnswers = new Array();
		_scoreQIDs = new Array();
		_scoreSelectedAnswerIds = new Array();
	}
	/**
	 * Gathers stage size information and draws the background and User Interface
	 */
	private function initUI():void
	{
		// store reference to stage dimensions
		_stageDim = new Dimension(widget.width, widget.height);
		//------------------------------
		// Draw BG
		//------------------------------
		// Draw the BG Grid
		var bgBitmapData:BitmapData = new BitmapData(GRID_WIDTH, GRID_HEIGHT, false, COLOR_BG);
		var i:int;
		for(i = 0; i < bgBitmapData.width; i+= GRID_SPACING)
		{
			bgBitmapData.setPixel(i,0,COLOR_GRID);
			bgBitmapData.setPixel(0,i,COLOR_GRID);
		}
		this.graphics.beginBitmapFill(bgBitmapData);
		this.graphics.drawRect(0,0,_stageDim.width, _stageDim.height);
		// Create the Info Bar
		_infoBarDim = new Dimension(_stageDim.width, INFO_BAR_HEIGHT);
		_infoBar = new Sprite();
		_infoBar.graphics.beginFill(COLOR_ACCENT_1);
		_infoBar.graphics.drawRect(0, 0, _infoBarDim.width, _infoBarDim.height);
		var _infoBarBitmapData:BitmapData = new BitmapData(2, _infoBarDim.height, false, COLOR_ACCENT_1);
		_infoBarBitmapData.setPixel(0, _infoBarDim.height - INFO_BAR_PADDING_V, COLOR_INFO_BAR_UNDERLINE);
		_infoBarBitmapData.setPixel(0, _infoBarDim.height - 2, COLOR_INFO_BAR_BORDER_1);
		_infoBarBitmapData.setPixel(0, _infoBarDim.height - 1, COLOR_INFO_BAR_BORDER_2);
		_infoBarBitmapData.setPixel(0, _infoBarDim.height - 0, COLOR_INFO_BAR_BORDER_3);
		_infoBarBitmapData.setPixel(1, _infoBarDim.height - 2, COLOR_INFO_BAR_BORDER_1);
		_infoBarBitmapData.setPixel(1, _infoBarDim.height - 1, COLOR_INFO_BAR_BORDER_2);
		_infoBarBitmapData.setPixel(1, _infoBarDim.height - 0, COLOR_INFO_BAR_BORDER_3);
		_infoBar.graphics.beginBitmapFill(_infoBarBitmapData);
		_infoBar.graphics.drawRect(0, 0, _infoBarDim.width, _infoBarDim.height);
		this.addChild(_infoBar);
		//------------------------------
		// Draw HUD
		//------------------------------
		// Create the Title Field
		_titleField = new TextField();
		initTextField(_titleField, FORMAT_TITLE, inst.name);
		_titleField.wordWrap = false;
		_titleField.x = INFO_BAR_PADDING_H;
		_titleField.y = _infoBarDim.height - INFO_BAR_PADDING_V - _titleField.textHeight + 3;
		_infoBar.addChild(_titleField);
		// Create the background box that goes behind question and asset box
		_bgBox = new Sprite();
		this.addChild(_bgBox);
		// Draw Question Box
		_questionBoxDim = new Dimension(600, 200);
		_questionBox = new Sprite();
		_questionBox.graphics.beginFill(COLOR_BOX_BG);
		_questionBox.graphics.drawRect(0, 0, _questionBoxDim.width, _questionBoxDim.height);
		_questionBox.y = _infoBarDim.height + PADDING_V;
		_questionBox.x = (_stageDim.width - _questionBoxDim.width) / 2;
		this.addChild(_questionBox);
		// Draw question field
		_questionField = new ScrollText(_questionBoxDim.width - PADDING_H * 2, _questionBoxDim.height - PADDING_V * 2);
		initScrollText(_questionField, FORMAT_QUESTION, "Widget was not loaded properly");
//		_questionField.width = _questionBoxDim.width - PADDING_H * 2;
		_questionField.x = PADDING_H;
		_questionField.y = PADDING_V;
		_questionBox.addChild(_questionField);
		// Draw answer box
		_answerBoxDim = new Dimension(600, 150);
		_answerBoxContainer = new ScrollClip(_answerBoxDim.width, _answerBoxDim.height, true);
		_answerBoxContainer.setStyle("bgFill", COLOR_BOX_BG);
		_answerBoxContainer.setStyle("bgAlpha", 1);
		_answerBox = new Sprite();
		_answerBox.opaqueBackground = COLOR_BOX_BG;
		_answerBoxContainer.x = _stageDim.width / 2 - _answerBoxDim.width / 2;
		_answerBoxContainer.y = _stageDim.height * 2 / 3 - _answerBoxDim.height / 2;
		_answerBoxContainer.clip.addChild(_answerBox);
		this.addChild(_answerBoxContainer);
		// Draw short answer box
		_shortAnswerBox = new Sprite();
		_shortAnswerDim = new Dimension(_stageDim.width * 2 / 3, 40);
		_shortAnswerButton = new AdventureButton();
		_shortAnswerButton.update("Submit", _shortAnswerDim.height);
		_shortAnswerButton.x = _shortAnswerDim.width - _shortAnswerButton.width;
		_shortAnswerButton.addEventListener(MouseEvent.CLICK, onShortAnswerButtonSubmit, false, 0, true);
		_shortAnswerField = new TextField();
		_shortAnswerField.restrict = "^\u0001-\u0008\u000B-\u001F";
		_shortAnswerField.type = TextFieldType.INPUT;
		_shortAnswerField.defaultTextFormat = FORMAT_SHORT_ANSWER;
		_shortAnswerField.width = _shortAnswerDim.width - _shortAnswerButton.width - PADDING_H;
		_shortAnswerField.height = _shortAnswerDim.height;
		_shortAnswerField.background = true;
		_shortAnswerField.backgroundColor = COLOR_BOX_BG;
		_shortAnswerField.border = true;
		_shortAnswerField.borderColor = COLOR_BOX_BORDER;
		_shortAnswerField.addEventListener(KeyboardEvent.KEY_UP, onShortAnswerFieldKeyUp, false, 0, true);
		var shortAnswerLabel:TextField = createLabel("Type Your Answer Here:");
		shortAnswerLabel.y = -shortAnswerLabel.height;
		_shortAnswerBox.addChild(_shortAnswerButton);
		_shortAnswerBox.addChild(_shortAnswerField);
		_shortAnswerBox.addChild(shortAnswerLabel);
		this.addChild(_shortAnswerBox);
		// Draw continue button
		_continueButton = new AdventureButton();
		_continueButton.addEventListener(MouseEvent.CLICK, onContinueClick, false, 0, true);
		this.addChild(_continueButton);
		updateContinueButton("Continue", 0);
		// Create the asset box
		_assetBox = new Sprite();
		this.addChild(_assetBox);
		// Create the hotspot box
		_hotspotBox = new Sprite();
		this.addChild(_hotspotBox);
		//------------------------------
		// Draw Feedback Box
		//------------------------------
		// Create feedback box components
		_feedbackBox = new Sprite();
		_feedbackModal = new Sprite();
		_feedbackBoxDim = DIM_FEEDBACK;
		// Draw Modal
		_feedbackModal.graphics.beginFill(FEEDBACK_MODAL_COLOR, FEEDBACK_MODAL_ALPHA);
		_feedbackModal.graphics.drawRect(0, 0, _stageDim.width, _stageDim.height);
		_feedbackModal.graphics.endFill();
		_feedbackModal.visible = false;
		// Draw Feedback Box
		_feedbackBox.graphics.beginFill(COLOR_BOX_BG);
		_feedbackBox.graphics.lineStyle(FEEDBACK_BORDER_STROKE, FEEDBACK_BORDER_COLOR);
		_feedbackBox.graphics.drawRect(0, 0, _feedbackBoxDim.width, _feedbackBoxDim.height);
		_feedbackBox.x = (_stageDim.width - _feedbackBoxDim.width) / 2;
		_feedbackBox.y = (_stageDim.height - _feedbackBoxDim.height) / 2;
		_feedbackBox.graphics.endFill();
		_feedbackModal.addChild(_feedbackBox);
		// Draw Label
		var feedbackLabel:TextField = createLabel("FEEDBACK:");
		feedbackLabel.x = _feedbackBox.x - FEEDBACK_BORDER_STROKE / 2;
		feedbackLabel.y = _feedbackBox.y - feedbackLabel.height - FEEDBACK_BORDER_STROKE / 2;
		_feedbackModal.addChild(feedbackLabel);
		// Draw Continue Button
		_feedbackButton = new AdventureButton();
		_feedbackButton.update("OK");
		_feedbackButton.x = (_feedbackBoxDim.width - _feedbackButton.width) / 2;
		_feedbackButton.y = _feedbackBoxDim.height - _feedbackButton.height - PADDING_V;
		_feedbackButton.focusRect = false;
		_feedbackBox.addChild(_feedbackButton);
		// Draw Feedback TextField
		var w:Number = _feedbackBoxDim.width - PADDING_H * 2;
		var h:Number = _feedbackBoxDim.height - BUTTON_HEIGHT - PADDING_V * 3;
		var txt:String = "Feedback";
		_feedbackBoxText = new ScrollText(w, h, txt, FORMAT_QUESTION);
		initScrollText(_feedbackBoxText, FORMAT_QUESTION, txt);
		_feedbackBoxText.width = _feedbackBoxDim.width - PADDING_H * 2;
		_feedbackBoxText.height = _feedbackBoxDim.height - BUTTON_HEIGHT - PADDING_V * 3;
		_feedbackBoxText.x = PADDING_H;
		_feedbackBoxText.y = PADDING_V;
		_feedbackBox.addChild(_feedbackBoxText);
		// Add to Stage
		this.addChild(_feedbackModal);
		//------------------------------
		// Initialize Layout Variables
		//------------------------------
		_horizDim = new Dimension(_stageDim.width / 2 - PADDING_H * 2, _stageDim.height - INFO_BAR_HEIGHT - _continueButton.height - PADDING_V * 3);
		_vertDim = new Dimension(_stageDim.width - PADDING_H * 8, (_stageDim.height - INFO_BAR_HEIGHT - _continueButton.height - PADDING_V * 3) / 2 - PADDING_V / 2);
	}
	/**
	 * Clears all elements specific to last node from the UI to make way for
	 * a new node's contents. Hides all uncommonly used components.
	 */
	private function clearUI():void
	{
		// clear question field
		_questionField.text = "";
		// clear answers from answer box
		while(_answerBox.numChildren != 0)
		{
			var removed:AnswerField = AnswerField(_answerBox.removeChildAt(0));
			removed.removeEventListener(MouseEvent.MOUSE_OVER, onMouseOverField);
			removed.removeEventListener(MouseEvent.MOUSE_OUT, onMouseOutField);
			removed.removeEventListener(MouseEvent.CLICK, onMouseClickField);
		}
		_continueButton.visible = false;
		_answerBoxContainer.visible = false;
		_assetBox.visible = false;
		_hotspotBox.visible = false;
		_bgBox.visible = false;
		_shortAnswerBox.visible = false;
	}
	/**
	 * Sets the type icon to the left of the question field.
	 * Use null to remove the icon.
	 * @param icon The embedded object (class) to load the image from
	 */
	private function setTypeIcon(icon:Class):void
	{
		// Remove Previous Icon
		if(_typeIcon != null) _questionBox.removeChild(_typeIcon);
		if(icon == null && _typeIconIncluded)
		{
			_typeIconIncluded = false;
			_typeIcon = null;
		}
		else if (icon != null)
		{
			_typeIconIncluded = true;
			_typeIcon = new icon;
			_typeIcon.x = PADDING_H;
			_typeIcon.y = PADDING_V;
			_questionBox.addChild(_typeIcon);
		}
	}
	private function updateQuestionBox(newDim:Dimension, position:int, bounds:Rectangle = null):void
	{
		_questionBox.visible = true;
		// Resize the container
		_questionBoxDim = newDim;
		_questionBox.graphics.clear();
		_questionBox.graphics.beginFill(COLOR_BOX_BG);
		_questionBox.graphics.drawRect(0, 0, _questionBoxDim.width, _questionBoxDim.height);
		_questionField.width = _questionBoxDim.width - PADDING_H * 2;
		_questionField.height = _questionBoxDim.height - PADDING_V * 2;
		// Resize the question field
		var iconSpace:Number = PADDING_H + ICON_SIZE;
		_questionField.width = _questionBoxDim.width - PADDING_H * 2 - (_typeIconIncluded ? iconSpace : 0);
		_questionField.x = PADDING_H + (_typeIconIncluded ? iconSpace: 0);
		_questionField.y = PADDING_V + QUESTION_FIELD_OFFSET_Y;
		// Reposition
		repositionComponent(_questionBox, _questionBoxDim, position, bounds);
	}
	private function updateAssetBox(newDim:Dimension, entry:Object, position:int, bounds:Rectangle = null):void
	{
		_assetBox.visible = true;
		_assetBoxDim = newDim.clone();
		_assetBoxDim.width -= PADDING_ASSET * 2;
		_assetBoxDim.height -= PADDING_ASSET * 2;
		repositionComponent(_assetBox, _assetBoxDim, position, bounds);
//		_assetBox.y += PADDING_ASSET;
//		_assetBox.width -= PADDING_ASSET * 2;
//		_assetBox.height -= PADDING_ASSET * 2;
		getImageAssetSprite(entry.options.assetId, onAssetLoaded, entry);
	}
	private function updateBgBox():void
	{
		var x1:Number = Math.min(_questionBox.x, _assetBox.x - PADDING_ASSET);
		var y1:Number = Math.min(_questionBox.y, _assetBox.y - PADDING_ASSET);
		var x2:Number = Math.max(_questionBox.x + _questionBoxDim.width, _assetBox.x + _assetBoxDim.width + PADDING_ASSET);
		var y2:Number = Math.max(_questionBox.y + _questionBoxDim.height, _assetBox.y + _assetBoxDim.height + PADDING_ASSET);
		_bgBoxDim = new Dimension(x2-x1, y2-y1);
		_bgBox.graphics.clear();
		_bgBox.graphics.beginFill(COLOR_BOX_BG);
		_bgBox.graphics.drawRect(0, 0, _bgBoxDim.width, _bgBoxDim.height);
		_bgBox.x = x1;
		_bgBox.y = y1;
		_bgBox.visible = true;
	}
	/**
	 * Places the component at the given position. Assumes the component has
	 * already been given its desired size.
	 */
	private function repositionComponent(component:DisplayObject, componentDim:Dimension, position:int, bounds:Rectangle = null):void
	{
		// Create component dim if not specified
		if(componentDim == null) componentDim = new Dimension(component.width, component.height);
		// Create bounds if not specified
		if(bounds == null) bounds = new Rectangle(0, 0, _stageDim.width, _stageDim.height);
		/* Add Common Componenets to Bounds */
		var myBounds:Rectangle = bounds;
		myBounds.y += INFO_BAR_HEIGHT + PADDING_V;
		myBounds.height += -INFO_BAR_HEIGHT - PADDING_V * 2;
		switch(position)
		{
			case POSITION_TOP:
				component.x = myBounds.x + (myBounds.width - componentDim.width) / 2;
				component.y = myBounds.y + ((myBounds.height)/2 - componentDim.height) / 2;
				break;
			case POSITION_BOTTOM:
				component.x = myBounds.x + (myBounds.width - componentDim.width) / 2;
				component.y = myBounds.y + ((myBounds.height)/2 - componentDim.height) / 2 + (myBounds.height) / 2;
				break;
			case POSITION_LEFT:
				component.x = myBounds.x + ((myBounds.width/2) - componentDim.width) / 2;
				component.y = myBounds.y + ((myBounds.height) - componentDim.height) / 2;
				break;
			case POSITION_RIGHT:
				component.x = myBounds.x + ((myBounds.width/2) - componentDim.width) / 2 + (myBounds.width/2);
				component.y = myBounds.y + ((myBounds.height) - componentDim.height) / 2;
				break;
			case POSITION_CENTER:
				component.x = myBounds.x + (myBounds.width - componentDim.width) / 2;
				component.y = myBounds.y + (myBounds.height - componentDim.height) / 2;
				break;
			default:
				throw new Error("Invalid position specified: " + position);
				break;
		}
	}
	/**
	 * Loads a node at the given index. Calls loadNode() again with an index
	 * based on the answer chosen or finish() if it is an end node.
	 * Administers any penalties or bonuses associated with arriving to this
	 * node and with answering the question a certain way.
	 *
	 * @param index The position in the itmes[0][i] array from the qSet to load a question from
	 */
	private function loadNode(nodeID:int):void
	{
		var i:int;
		var isEmptyNode:Boolean = false;
		// Submit for scoring if target is score screen
		if(nodeID == SCORE_SCREEN_ID)
		{
			submitForScoring();
			return;
		}
		// find the node with the given ID
		for(i = 0; i < _mGroup.items.length; i++)
		{
			if(int(_mGroup.items[i].options.id) == nodeID) break;
		}
		var entry:Object = (_mGroup.items[i]);
		// store reference to next node for easy/clean access
		_currentNode = entry;
		// clean the canvas
		clearUI();
		//----------------------------------------------------------------------
		//
		//  Adjust According to Type & Layout
		//
		//----------------------------------------------------------------------
		var bounds:Rectangle;
		switch(entry.options.type)
		{
			//----------------------------------
			//  Narrative/End Node
			//----------------------------------
			case AdventureOptions.TYPE_NARRATIVE:
			case AdventureOptions.TYPE_END:
				var end:Boolean = entry.options.type == AdventureOptions.TYPE_END;
				setTypeIcon(null);
				// get text to be used for proceed button
				var proceedText:String = entry.options.proceedText;
				// apply score for end node
				// if(end && _scoreStyle == AdventureOptions.SCORESTYLE_DESTINATION) applyScore(entry, 0);
				if (end) applyScore(entry, 0);
				// get node to link to for next target
				var target:int;
				if(end) target = SCORE_SCREEN_ID;
				else target = entry.answers[0].options.link;
				// update continue button
				updateContinueButton(proceedText, target);
				// calculate restrictive bounds for the given components
				bounds = new Rectangle(0, 0, _stageDim.width, _stageDim.height - (_continueButton.height + PADDING_V));
				switch(entry.options.layout)
				{
					case AdventureOptions.LAYOUT_TEXT_ONLY:
						updateQuestionBox(_vertDim.clone(), POSITION_CENTER, bounds.clone());
						break;
					case AdventureOptions.LAYOUT_VERT_TEXT:
						updateQuestionBox(_vertDim.clone(), POSITION_TOP, bounds.clone());
						updateAssetBox(_vertDim.clone(), entry, POSITION_BOTTOM, bounds.clone());
						updateBgBox();
						break;
					case AdventureOptions.LAYOUT_VERT_IMAGE:
						updateQuestionBox(_vertDim.clone(), POSITION_BOTTOM, bounds.clone());
						updateAssetBox(_vertDim.clone(), entry, POSITION_TOP, bounds.clone());
						updateBgBox();
						break;
					case AdventureOptions.LAYOUT_HORIZ_TEXT:
						updateQuestionBox(_horizDim.clone(), POSITION_LEFT, bounds.clone());
						updateAssetBox(_horizDim.clone(), entry, POSITION_RIGHT, bounds.clone());
						updateBgBox();
						break;
					case AdventureOptions.LAYOUT_HORIZ_IMAGE:
						updateQuestionBox(_horizDim.clone(), POSITION_RIGHT, bounds.clone());
						updateAssetBox(_horizDim.clone(), entry, POSITION_LEFT, bounds.clone());
						updateBgBox();
						break;
					default:
						throw new Error("Invalid or missing layout");
						break;
				}
				break;
			//----------------------------------
			//  Multiple Choice & Short Answer
			//----------------------------------
			case AdventureOptions.TYPE_MULTIPLE_CHOICE:
			case AdventureOptions.TYPE_SHORT_ANSWER:
				var qBoxDim:Dimension;
				var qBoxHeightModifier:Number = 0;
				if(entry.options.type == AdventureOptions.TYPE_SHORT_ANSWER) qBoxHeightModifier = _stageDim.height / 4;
				bounds = new Rectangle(0, 0, _stageDim.width, (_stageDim.height - INFO_BAR_HEIGHT - PADDING_V * 2) / 2 + qBoxHeightModifier + INFO_BAR_HEIGHT + PADDING_V * 2);
				var hasAsset:Boolean = false;
				switch(entry.options.layout)
				{
					case AdventureOptions.LAYOUT_HORIZ_TEXT:
						qBoxDim = new Dimension(_stageDim.width / 2 - PADDING_H * 2, _stageDim.height / 2 - PADDING_V * 2 + qBoxHeightModifier);
						_assetBox.visible = true;
						updateQuestionBox(qBoxDim, POSITION_LEFT, bounds.clone());
						updateAssetBox(qBoxDim.clone(), entry, POSITION_RIGHT, bounds.clone());
						updateBgBox();
						break;
					case AdventureOptions.LAYOUT_HORIZ_IMAGE:
						qBoxDim = new Dimension(_stageDim.width / 2 - PADDING_H * 2, _stageDim.height / 2 - PADDING_V * 2 + qBoxHeightModifier);
						_assetBox.visible = true;
						updateQuestionBox(qBoxDim, POSITION_RIGHT, bounds.clone());
						updateAssetBox(qBoxDim.clone(), entry, POSITION_LEFT, bounds.clone());
						updateBgBox();
						break;
					case AdventureOptions.LAYOUT_TEXT_ONLY:
					default:
						qBoxDim = new Dimension(_stageDim.width - PADDING_H * 2, _stageDim.height / 2 - PADDING_V * 2 + qBoxHeightModifier);
						updateQuestionBox(qBoxDim, POSITION_CENTER, bounds.clone());
						break;
				}
				if(entry.options.type == AdventureOptions.TYPE_MULTIPLE_CHOICE)
				{
					/* Multiple Choice */
					// Copy array from qset
					var answers:Array = new Array();
					for(i = 0; i < (entry.answers as Array).length; i++) answers.push(entry.answers[i]);
					// Update the Question Box
					setTypeIcon(null);
					_answerBoxContainer.visible = true;
					repositionComponent(_answerBoxContainer, _answerBoxDim, POSITION_BOTTOM);
					// Store original array positions
					for(i = 0; i < answers.length; i++)
					{
						answers[i].options.originalIndex = i;
					}
					// Shuffle the Araray if Random Option Enabled
					if(entry.options.randomize)
					{
						for(i = answers.length - 1; i >= 0; i--)
						{
							var t:Object = answers[i];
							var rand:int = Math.floor(Math.random() * (answers.length));
							answers[i] = answers[rand];
							answers[rand] = t;
						}
					}
					// load the answers into the answer box
					for(i = 0; i < answers.length; i++)
					{
						var answer:Object = Object(answers[i]);
						// create the interactive answer field
						var answerField:AnswerField = new AnswerField(answer.options.originalIndex, answer, entry.id, answers[i].options.feedback);
						initTextField(answerField, FORMAT_CHOICE, String.fromCharCode('A'.charCodeAt(0) + i) + ") " + answer.text);
						answerField.width = _answerBoxDim.width - PADDING_TEXT * 2;
						answerField.mouseEnabled = true;
						answerField.addEventListener(MouseEvent.MOUSE_OVER, onMouseOverField, false, 0, true);
						answerField.addEventListener(MouseEvent.MOUSE_OUT, onMouseOutField, false, 0, true);
						answerField.addEventListener(MouseEvent.CLICK, onMouseClickField, false, 0, true);
						// position the new answer option
						answerField.x = PADDING_TEXT;
						answerField.y = PADDING_TEXT;
						if(i != 0)
						{
							var lastField:TextField = TextField(_answerBox.getChildAt(_answerBox.numChildren - 1));
							answerField.y = lastField.y + lastField.height;
						}
						// add it to the box
						_answerBox.addChild(answerField);
					}
				}
				else
				{
					/* Short Answer */
					_shortAnswerBox.visible = true;
					var _shortAnswerBounds:Rectangle = new Rectangle (0, bounds.height, _stageDim.width, _stageDim.height - bounds.height - PADDING_H * 2);
					repositionComponent(_shortAnswerBox, _shortAnswerDim, POSITION_BOTTOM, _shortAnswerBounds);
					_shortAnswerField.text = "";
					this.addChild(_shortAnswerBox);
					this.stage.focus = _shortAnswerField;
				}
				break;
			//----------------------------------
			//  Hotspot
			//----------------------------------
			case AdventureOptions.TYPE_HOTSPOT:
				// Update the Question Box
				if(entry.options.layout == AdventureOptions.LAYOUT_VERT_TEXT && entry.questions[0].text)
				{
					setTypeIcon(ICON_HOTSPOT);
					updateQuestionBox(DIM_QUESTION_HOTSPOT, POSITION_TOP);
					_questionBox.y = INFO_BAR_HEIGHT + PADDING_V;
				}
				else
				{
					_questionBox.visible = false;
				}
				// Update the hotspot box
				var qBoxSize:Number = _questionBox.visible ? _questionBoxDim.height + PADDING_V : 0;
				_hotspotBoxDim = new Dimension(_stageDim.width - PADDING_H * 2, _stageDim.height - INFO_BAR_HEIGHT - qBoxSize - PADDING_V * 2);
				repositionComponent(_hotspotBox, _hotspotBoxDim, POSITION_CENTER, new Rectangle(0, qBoxSize, _stageDim.width, _stageDim.height - qBoxSize));
				// Load the image
				getImageAssetSprite(entry.options.assetId, onHotspotAssetLoaded, entry);
				_hotspotBox.visible = true;
				break;
			//----------------------------------
			//  Other
			//----------------------------------
			default: // Assume this is an end node for now
				// throw new Error("Invalid or missing node type");
				isEmptyNode = true;
				// break;
		}
		// load the question into the question field
		_questionField.text = String(entry.questions[0].text);
		// adjust font fize for large question text strings
		if (_questionField.text.length > 30)
		{
			_questionField.setStyle('textFormat', new TextFormat("ClassicRound", 22, COLOR_TEXT_MAIN, true));
			// ensure scrollbar is only enabled if necessary
			_questionField.checkScrollability();
		}

		// If the node is empty, determine whether or not the node is at the end of a branch - and proceed or go to score screen.
		if(isEmptyNode)
		{
			bounds = new Rectangle(0, 0, _stageDim.width, _stageDim.height - (_continueButton.height + PADDING_V));
			// Update layout
			setTypeIcon(null);

			try
			{
				if (entry.answers[0].options.link)
				{
					updateContinueButton("Continue", entry.answers[0].options.link);
					_questionField.text = String("This node is empty. Click the continue button to advance to the next one.");
				}
			}
			catch (e:Error)
			{
				updateContinueButton("Visit Score Screen", SCORE_SCREEN_ID);
				_questionField.text = String("This node is empty, and is the final node on this branch. Click the button below to proceed to the score screen.");

				_scoreQIDs.push(0);
				_scoreSelectedAnswers.push("Empty Node");
				_scoreSelectedAnswerIds.push('');
				_selectedFinalAnswer = "Empty Node";
			}

			updateQuestionBox(_vertDim, POSITION_CENTER, bounds);
		}
	}
	/**
	 * Applies the score obtained by choosing the given answer index
	 * on the given question
	 *
	 * @param the question that was answered
	 * @param the answer index to get score change from
	 */
	private function applyScore(question:Object, answerIndex:int):void
	{
		if(question == null) return;

		/* manage end node */
		if (question.options.type == AdventureOptions.TYPE_END)
		{
			_selectedFinalAnswer = question.questions[0].text;
			return;
			// _scoreQIDs.push(question.id);
			// _scoreSelectedAnswers.push(_selectedFinalAnswer);
		}

		var selectedAnswer:Object = question.answers[answerIndex];

		_scoreQIDs.push(question.id);
		_scoreSelectedAnswers.push(selectedAnswer.text);

		if (question.options.type == AdventureOptions.TYPE_HOTSPOT)
		{
			_scoreSelectedAnswerIds.push(selectedAnswer.id);
		}
		else
		{
			_scoreSelectedAnswerIds.push('');
		}
		/*
		===========================================================
		Old scoring logic for Quiz & Quest follows
		===========================================================
		*/

		/*
		else
		{
			var selectedAnswer:Object = question.answers[answerIndex];
			// _scoreQIDs.push(question.id);

			switch(_scoreStyle)
			{
				case AdventureOptions.SCORESTYLE_QUIZ:
					if(!selectedAnswer.options.validScore) break;
					if(selectedAnswer.value < 0) break;

					break;
				case AdventureOptions.SCORESTYLE_QUEST:
					if(!selectedAnswer.options.validScoreModification) break;
					if(!selectedAnswer.options.scoreModification) break;

					break;
				default:
					break;
			}

			_scoreQIDs.push(question.id);

			_scoreSelectedAnswers.push(selectedAnswer.text);

			if (question.options.type == AdventureOptions.TYPE_HOTSPOT)
			{
				_scoreSelectedAnswerIds.push(selectedAnswer.id);
			}
			else
			{
				_scoreSelectedAnswerIds.push('');
			}
			_scoreSelectedAnswers.push(selectedAnswer.text);

		}
		*/
	}

	/**
	 * Loads the given image into _assetBox. Assumes _assetBox has already been
	 * given a size and determines the image's scale from that.
	 */
	private function onAssetLoaded(image:DisplayObject, data:Object):void
	{
		var i:int;
		// Remove any previously added children
		for(i = 0; i < _assetBox.numChildren; i++)
		{
			_assetBox.removeChildAt(i);
		}
		// Add the image
		_assetBox.addChild(image);
		image.scaleX = image.scaleY = Math.min(_assetBoxDim.width / image.width, _assetBoxDim.height / image.height);
		image.width -= 2;
		image.height -= 2;
		image.x = (_assetBoxDim.width - image.width) / 2;
		image.y = (_assetBoxDim.height - image.height) / 2;
		// Draw the Border
		_assetBox.graphics.clear();
		_assetBox.graphics.beginFill(COLOR_BOX_BORDER);
		for(i = 0; i < _assetBoxDim.width; i += GRID_SPACING)
		{
			_assetBox.graphics.drawRect(i, 0, 1, 1);
			_assetBox.graphics.drawRect(i, _assetBoxDim.height, 1, 1);
		}
		for(i = GRID_SPACING; i < _assetBoxDim.height; i += GRID_SPACING)
		{
			_assetBox.graphics.drawRect(0, i, 1, 1);
			_assetBox.graphics.drawRect(_assetBoxDim.width, i, 1, 1);
		}
	}
	private function onHotspotAssetLoaded(image:DisplayObject, data:Object):void
	{
		var i:int;
		// Remove any previously added children
		while(_hotspotBox.numChildren)
		{
			var removed:DisplayObject = DisplayObject(_hotspotBox.removeChildAt(0));
			if(removed is AdventureDisplayHotspot) destroyHotspot(AdventureDisplayHotspot(removed));
		}
		_hotspotBox.removeEventListener(MouseEvent.CLICK, onHotspotMissed);
		// Draw the Border
//		_hotspotBox.graphics.lineStyle(1, COLOR_BOX_BORDER);
//		_hotspotBox.graphics.drawRect(0, 0, _hotspotBoxDim.width, _hotspotBoxDim.height);
		// Adjust image scale and position
		image.scaleX = image.scaleY = Math.min(_hotspotBoxDim.width / image.width, _hotspotBoxDim.height / image.height);
		image.x = (_hotspotBoxDim.width - image.width) / 2;
		image.y = (_hotspotBoxDim.height - image.height) / 2;
		// Add the Image
		_hotspotBox.addChild(image);
		// Load the Hotspots
		if(data.answers == null)
		{
			// if there are no hotspots, we're done (should only happen in previews)
			return;
		}
		for(i = 0; i < data.answers.length; i++)
		{
			// Manage default hotspot
			if(i == 0 && data.answers[i].options.isDefault)
			{
				_hotspotBox.addEventListener(MouseEvent.CLICK, onHotspotMissed, false, 0, true);
				_hotspotDefaultAnswer = data.answers[i];
				continue;
			}
			// Load data about hotspot from qset
			var hotspotData:AdventureHotspot = AdventureUtils.decodeHotspot(data.answers[i].options.hotspot);
			// Create the Hotspot Sprite Reference
			var hotspot:AdventureDisplayHotspot;
			// Determine Hotspot Type and Instantiate
			switch(hotspotData.type)
			{
				case AdventureOptions.HOTSPOT_RECT:
					hotspot = new AdventureHotspotRect(image, false, data.options.visibility);
					break;
				case AdventureOptions.HOTSPOT_ELLIPSE:
					hotspot = new AdventureHotspotEllipse(image, false, data.options.visibility);
					break;
				case AdventureOptions.HOTSPOT_POLYGON:
					hotspot = new AdventureHotspotPolygon(image, false, data.options.visibility);
					break;
				default:
					throw new Error("Missing or invalid hotspot type.");
					break;
			}
			// save position in the answer array
			hotspot.id = i;
			// Set Hotspot Metadata
			if(data.options.hotspotColor != null) hotspot.color = data.options.hotspotColor;
			if(data.options.visibility != AdventureOptions.VISIBILITY_NEVER) ToolTip.add(hotspot, data.answers[i].text, {showDelay:0, hideDelay:0});
			hotspot.data = data.answers[i];
			hotspot.addEventListener(MouseEvent.CLICK, onClickHotspot, false, 0, true);
			// Draw and Add Hotspot
			_hotspotBox.addChild(hotspot);
			hotspot.build(hotspotData.points);
		}
	}
	private function destroyHotspot(hotspot:AdventureDisplayHotspot):void
	{
		hotspot.removeEventListener(MouseEvent.CLICK, onClickHotspot);
		ToolTip.remove(hotspot);
	}
	private function onClickHotspot(e:MouseEvent):void
	{
		e.stopImmediatePropagation();
		var hotspot:AdventureDisplayHotspot = AdventureDisplayHotspot(e.target);
		applyScore(_currentNode, hotspot.id);
		if(hotspot.data.options.feedback == null || !hotspot.data.options.feedback.length) loadNode(hotspot.data.options.link);
		else showFeedback(hotspot.data.options.feedback, hotspot.data.options.link);
	}
	private function onHotspotMissed(e:MouseEvent):void
	{
		applyScore(_currentNode, 0);
		if(_hotspotDefaultAnswer.options.feedback == null || !_hotspotDefaultAnswer.options.feedback.length) loadNode(_hotspotDefaultAnswer.options.link);
		else showFeedback(_hotspotDefaultAnswer.options.feedback, _hotspotDefaultAnswer.options.link);
	}
	private function showFeedback(feedback:String, targetNode:int):void
	{
		_feedbackModal.visible = true;
		_buttonTarget = targetNode;
		_feedbackBoxText.text = feedback;
		_feedbackButton.addEventListener(MouseEvent.CLICK, hideFeedback, false, 0, true);
		_feedbackButton.addEventListener(KeyboardEvent.KEY_UP, onFeedbackButtonKeyUp, false, 0, true);
		stage.focus = _feedbackButton;
	}
	private function hideFeedback(e:Event = null):void
	{
		_feedbackModal.visible = false;
		_feedbackButton.removeEventListener(MouseEvent.CLICK, hideFeedback);
		_feedbackButton.addEventListener(KeyboardEvent.KEY_UP, onFeedbackButtonKeyUp);
		loadNode(_buttonTarget);
	}
	private function onMouseOverField(e:MouseEvent):void
	{
		TextField(e.target).filters = FILTERSET_CHOICE;
	}
	private function onMouseOutField(e:MouseEvent):void
	{
		TextField(e.target).filters = [];
	}
	private function onMouseClickField(e:MouseEvent):void
	{
		var answerField:AnswerField = AnswerField(e.target);
		// manageScoreModifier(answerField.answer.options.scoreModifier);
		applyScore(_currentNode, answerField.index);

		if(answerField.feedback == null) loadNode(answerField.answer.options.link);
		else showFeedback(answerField.feedback, answerField.answer.options.link);
	}
	private function onShortAnswerButtonSubmit(e:Event):void
	{
		submitShortAnswer();
	}
	private function onShortAnswerFieldKeyUp(e:KeyboardEvent):void
	{
		if(e.keyCode == Keyboard.ENTER)	submitShortAnswer();
	}
	private function onFeedbackButtonKeyUp(e:KeyboardEvent):void
	{
		if(e.keyCode == Keyboard.ENTER || e.keyCode == Keyboard.ESCAPE)
		{
			hideFeedback();
		}
	}
	private function submitShortAnswer():void
	{
		var entry:Object = _currentNode;
		var response:String = formatShortAnswer(_shortAnswerField.text);
		var destination:int = entry.answers[0].options.link;
		var feedback:String = entry.answers[0].options.feedback;
		var answerIndex:int = 0;
		// Cycle through possible paths
		outerLoop : for(var i:int = 1; i < entry.answers.length; i++)
		{
			// Cycle through possible answers for each path
			var pathAnswers:Array = String(entry.answers[i].text).split(new RegExp("(?<!\\\\),"));
			for(var j:int = 0; j < pathAnswers.length; j++)
			{
				var answer:String = formatShortAnswer(pathAnswers[j]);
				if(response == answer)
				{
					destination = entry.answers[i].options.link;
					feedback = entry.answers[i].options.feedback;
					answerIndex = i;
					break outerLoop;
				}
			}
		}
		applyScore(entry, answerIndex);
		if(feedback == null || !feedback.length) loadNode(destination);
		else showFeedback(feedback, destination);
	}
	/**
	 * Formats a short answer response or answer to minimize trivial errors by
	 * Trimming leading and trailing spaces and eliminating case sensitivity.
	 */
	private function formatShortAnswer(value:String):String
	{
		var i:int;
		/* Eliminate Leading Spaces and Commas */
		for(i = 0; i < value.length; i++) if(value.charAt(i) != ' ' && value.charAt(i) != ',') break;
		if(i != 0) value = value.substr(i);
		/* Eliminate Trailing Spaces & Commas */
		for(i = value.length - 1; i >= 0; i--) if(value.charAt(i) != ' ' && value.charAt(i) != ',') break;
		if(i != value.length - 1) value = value.substring(0, i + 1);
		/* Eliminate Double Spaces */
		var lastChar:String = '';
		for(i = 0; i < value.length; i++)
		{
			var current:String = value.charAt(i);
			if(lastChar == ' ' && current == ' ')
			{
				value = value.substring(0, i - 1) + value.substring(i);
				i--;
			}
			lastChar = current;
		}
		/* Convert to Lowercase */
		value = value.toLowerCase();
		/* Parse Escaped Commas */
		value = value.replace(new RegExp("\\\\" + ',', '\g'), ',');
		return value;
	}
	private function onContinueClick(e:Event):void
	{
		loadNode(_buttonTarget);
	}
	private function updateContinueButton(text:String, targetId:int):void
	{
		this.addChild(_continueButton); // bring to front
		_continueButton.visible = true;
		_continueButton.update(text);
		_continueButton.x = (_stageDim.width - _continueButton.width) / 2;
		_continueButton.y = (_stageDim.height - PADDING_V) - _continueButton.height;
		_buttonTarget = targetId;
	}

	/**
	 * Submits this game instance to the server for scoring and shows the score screen
	 */
	private function submitForScoring():void
	{
		/*
		============================================
		Old logic for Quiz & Quest scoring follows
		============================================
		*/

		/*
		var answerId:String;
		while (_scoreQIDs.length > 0)
		{
			switch (_scoreStyle) {

				case  AdventureOptions.SCORESTYLE_QUIZ:
					answerId = _scoreSelectedAnswerIds.shift();
					if (answerId.length > 0)
					{
						scoring.submitQuestionForScoring(_scoreQIDs.shift(), _scoreSelectedAnswers.shift(), answerId);
					}
					else
					{
						scoring.submitQuestionForScoring(_scoreQIDs.shift(), _scoreSelectedAnswers.shift());
					}
				break;

				case AdventureOptions.SCORESTYLE_QUEST:
					answerId = _scoreSelectedAnswerIds.shift();
					if (answerId.length > 0)
					{
						// scoring.submitAdjustmentForScoring(_scoreQIDs.shift(), _scoreSelectedAnswers.shift(), answerId);
						// TODO: find a way to add answerId as a param
						scoring.submitInteractionForScoring(_scoreQIDs.shift(), 'quest_score_adjustment', _scoreSelectedAnswers.shift());
					}
					else
					{
						scoring.submitInteractionForScoring(_scoreQIDs.shift(), 'quest_score_adjustment', _scoreSelectedAnswers.shift());
					}
				break;

				case AdventureOptions.SCORESTYLE_DESTINATION:
					scoring.submitQuestionForScoring(_scoreQIDs.shift(), _scoreSelectedAnswers.shift());
				break;
			}
		}
		*/

		while (_scoreQIDs.length > 0)
		{
			scoring.submitQuestionForScoring(_scoreQIDs.shift(), _scoreSelectedAnswers.shift());
			/*
			answerId = _scoreSelectedAnswerIds.shift();
			if (answerId.length > 0)
			{
				scoring.submitQuestionForScoring(_scoreQIDs.shift(), _scoreSelectedAnswers.shift(), answerId);
			}
			else
			{
				scoring.submitQuestionForScoring(_scoreQIDs.shift(), _scoreSelectedAnswers.shift());
			}
			*/
		}

		// technically the final answer should never be null...
		if (_selectedFinalAnswer != null)
		{
			scoring.submitFinalScoreFromClient('0', _selectedFinalAnswer, '');
		}
		else
		{
			scoring.submitFinalScoreFromClient('0', '', '0');
		}

		end();

	}
	/**
	 * Formats and customizes the given TextField with a set of common preferences
	 *
	 * @param The TextField to be reformatted
	 * @param format The text format to be used in this TextField
	 * @param text The text to initialize this TextField with
	 */
	private function initTextField(tf:TextField, format:TextFormat, text:String = ""):void
	{
		tf.mouseEnabled = false;
		tf.embedFonts = format == null ? false : true;
		tf.selectable = false;
		tf.multiline = true;
		tf.wordWrap = true;
		tf.defaultTextFormat = format;
		tf.text = text;
		tf.autoSize = TextFieldAutoSize.LEFT;
	}
	private function createLabel(text:String):TextField
	{
		var result:TextField = new TextField();
		result.mouseEnabled = false;
		result.embedFonts = true;
		result.selectable = false;
		result.defaultTextFormat = FORMAT_LABEL;
		result.text = text;
		result.autoSize = TextFieldAutoSize.LEFT;
		result.background = true;
		result.backgroundColor = COLOR_LABEL_BG;
		return result;
	}
	private function initScrollText(target:ScrollText, format:TextFormat, text:String):void
	{
		target.setStyle("showBorder", false);
		target.tf.border = false;
		target.tf.embedFonts = format == null ? false : true;
		if(format != null) target.setStyle("textFormat", format);
		target.tf.defaultTextFormat = format;
		target.tf.background = false;
		target.mouseEnabled = false;
		target.editable = false;
		target.selectable = false;
		target.text = text;
	}
}
}
//--------------------------------------------------------------------------
//
//  Helper Classes
//
//--------------------------------------------------------------------------
import flash.display.Sprite;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import Engine;
class AnswerField extends TextField
{
	public var index:int;
	public var answer:Object;
	public var id:int;
	public var feedback:String;
	public function AnswerField(index:int, answer:Object, id:int, feedback:String = null):void
	{
		this.index = index;
		this.answer = answer;
		this.id = id;
		this.feedback = feedback;
	}
}
class AdventureButton extends Sprite
{
	public var tf:TextField;
	public function AdventureButton():void
	{
		tf = new TextField();
		tf.mouseEnabled = false;
		tf.embedFonts = true;
		tf.selectable = false;
		tf.defaultTextFormat = Engine.FORMAT_TITLE;
		tf.text = "Continue";
		tf.autoSize = TextFieldAutoSize.LEFT;
		addChild(tf);
		tf.x = Engine.BUTTON_PADDING_H;
		tf.y = Engine.BUTTON_PADDING_V;
	}
	public function update(text:String, customHeight:int = 0):void
	{
		var buttonHeight:Number = customHeight == 0 ? Engine.BUTTON_HEIGHT : customHeight;
		this.tf.width = Engine.BUTTON_WIDTH_MAX;
		this.tf.text = text;
		this.tf.autoSize = TextFieldAutoSize.LEFT;
		this.graphics.clear();
		this.graphics.beginFill(Engine.COLOR_ACCENT_1);
		var buttonWidth:Number = Math.min(Math.max(this.tf.width + Engine.BUTTON_PADDING_H * 2, Engine.BUTTON_WIDTH_MIN), Engine.BUTTON_WIDTH_MAX);
		this.graphics.drawRect(0, 0, buttonWidth, buttonHeight);
		this.tf.x = (this.width - this.tf.width) / 2;
		tf.y = buttonHeight / 2 - tf.textHeight / 2;
	}
}
