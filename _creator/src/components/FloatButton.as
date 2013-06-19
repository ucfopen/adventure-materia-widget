package components {
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.filters.GlowFilter;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import mx.controls.Image;
	import mx.core.Application;
	import mx.core.UIComponent;
	public class FloatButton extends AdventureButton
	{
		private var _titleContainer:Sprite;
		public function FloatButton()
		{
			this.visible = false;
		}
		public function reposition(target:Image):void
		{
			if(target == null || target.content == null) return;
			var targetPoint:Point = target.localToGlobal(new Point(0, target.content.height));
			if(this.width < target.content.width) this.x = targetPoint.x + ANCHOR_PADDING;
			else this.x = targetPoint.x + target.content.width / 2 - this.width / 2 + ANCHOR_PADDING;
			this.y = targetPoint.y + ANCHOR_PADDING;
		}
		public function show(target:Image):void
		{
			PopUpManager.addPopUp(this, DisplayObject(Application.application), false);
			reposition(target);
			this.visible = true;
		}
		public function hide():void
		{
			this.visible = false;
			PopUpManager.removePopUp(this);
		}
	}
}