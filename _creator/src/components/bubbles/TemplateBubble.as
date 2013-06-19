package components.bubbles {
	import mx.core.UIComponent;
	public class TemplateBubble extends AdventureBubble
	{
		private const WIDTH:Number = 130;
		private const HEIGHT:Number = 140;
		private const BUTTON_WIDTH:int = 32;
		private const BUTTON_HEIGHT:int = 32;
		private const SPACING:int = 5;
		public function DestinationBubble()
		{
			super(WIDTH, HEIGHT, "Template Bubble:");
		}
		public override function show(target:Sprite):void
		{
			super.show(target);
			trace("Show");
		}
	}
}