package components
{
	import flash.filters.DropShadowFilter;
	import flash.filters.GlowFilter;
	import mx.controls.Button;
	import mx.effects.Glow;
	public class AdventureButton extends Button
	{
		import flash.display.DisplayObject;
		import flash.display.Sprite;
		import flash.filters.GlowFilter;
		import flash.text.TextFieldAutoSize;
		import mx.controls.ButtonLabelPlacement;
		import mx.controls.Image;
		import mx.core.mx_internal;
		use namespace mx_internal;
		public static const ANCHOR_PADDING:int = 2;
		protected static const MIN_WIDTH:int = 60;
		protected static const MIN_HEIGHT:int = 24;
		public var usePlus:Boolean = false;
		public var anchored:Boolean = false;
		public var rWidth:Number;
		public var rHeight:Number;
		[Embed(source="../assets/add-plus.png")]
		private var Plus:Class;
		public function AdventureButton()
		{
			super();
		}
		override protected function createChildren():void
		{
			buttonMode=true;
			if(!textField)
			{
				textField = new NonTruncatingUITextField();
				textField.styleName = this;
				textField.autoSize = TextFieldAutoSize.LEFT;
				addChild(DisplayObject(textField));
			}
			super.createChildren();
		}
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			graphics.clear();
			var drawWidth:Number;
			MIN_WIDTH > unscaledWidth ? drawWidth = MIN_WIDTH : drawWidth = unscaledWidth;
			var drawHeight:Number;
			MIN_HEIGHT > unscaledHeight ? drawHeight = MIN_HEIGHT : drawHeight = unscaledHeight;
			if(anchored)
			{
				graphics.beginFill(0xF0F0F0, 1);
				graphics.lineStyle(1,0xBEBEBE);
				graphics.moveTo(-ANCHOR_PADDING,-ANCHOR_PADDING);
				graphics.lineTo(drawWidth+ANCHOR_PADDING, -ANCHOR_PADDING);
				graphics.lineTo(drawWidth+ANCHOR_PADDING,drawHeight);
				graphics.curveTo(drawWidth+ANCHOR_PADDING,drawHeight+ANCHOR_PADDING,drawWidth,drawHeight+ANCHOR_PADDING);
				graphics.lineTo(0,drawHeight+ANCHOR_PADDING);
				graphics.curveTo(-ANCHOR_PADDING,drawHeight+ANCHOR_PADDING,-ANCHOR_PADDING,drawHeight);
				graphics.lineTo(-ANCHOR_PADDING,-ANCHOR_PADDING);
				this.filters = [new DropShadowFilter(2,90,0,.25,8,6)];
			}
			else
			{
				graphics.beginFill(0xF0F0F0, .7);
				graphics.drawRoundRect(-ANCHOR_PADDING,-ANCHOR_PADDING,drawWidth + (2*ANCHOR_PADDING),drawHeight + (2*ANCHOR_PADDING),ANCHOR_PADDING,ANCHOR_PADDING);
			}
			graphics.endFill();
			width = drawWidth;
			height = drawHeight;
			rWidth = drawWidth + ANCHOR_PADDING;
			rHeight = drawHeight + ANCHOR_PADDING;
			setStyle("fontSize", 11);
			setStyle("color", 0x484848);
			textField.y = (height-textField.height)/2;
			if(usePlus)
			{
				textField.x = (width - textField.width)/2 + 10;
				var plus:Sprite = new Sprite();
				plus.addChild(new Plus());
				addChild(plus);
				plus.x = 10;
				plus.y = (height - plus.height)/2;
			}
		}
		public function get padding():int { return ANCHOR_PADDING; }
	}
}