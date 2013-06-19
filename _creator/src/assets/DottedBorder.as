package assets
{
	import mx.core.UIComponent;
	public class DottedBorder extends UIComponent
	{
		private var gap:int = 2;
		public function DottedBorder()
		{
			super();
		}
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			graphics.clear();
			graphics.beginFill(0, 1);
			if(getStyle("gap"))
			{
				this.gap = getStyle("gap");
			}
			//drawBorder(this.x, this.y, unscaledWidth, unscaledHeight, this.gap);
			drawBorder(0, 0, unscaledWidth, unscaledHeight, this.gap);
		}
		public function drawLine(x1:Number, y1:Number, x2:Number, y2:Number, gaplen:int):void
		{
			if((x1 != x2) || (y1 != y2))
			{
				var len:Number = Math.sqrt((x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2));
				var steps:uint = len / gaplen;
				var stepcount:uint = 0;
				while((stepcount++) <= steps)
				{
					var drawx:Number;
					var drawy:Number;
					if(x1 == x2 && y1 != y2)
					{
						drawx = x1;
						if(y2 > y1)
						{
							drawy = y1 + ((stepcount-1) * gaplen);
						}
						else
						{
							drawy = y1 - ((stepcount-1) * gaplen);
						}
					}
					else if(y1 == y2 && x1 != x2)
					{
						drawy = y1;
						if(x2 > x1)
						{
							drawx = x1 + ((stepcount-1) * gaplen);
						}
						else
						{
							drawx = x1 - ((stepcount-1) * gaplen);
						}
					}
					graphics.drawEllipse(drawx,drawy,.5,.5);
				}
			}
		}
		private function drawBorder(x1:Number, y1:Number, width:Number, height:Number, gaplen:int):void
		{
			var ss:String = getStyle("borderSides");
			var sides:Array = ss.split(",");
			if(sides.indexOf('top') >= 0)
			{
				drawLine(x1, y1, x1 + width, y1, gaplen);
			}
			if(sides.indexOf('right') >= 0)
			{
				drawLine(x1 + width, y1 + gaplen, x1 + width, y1 + height, gaplen);
			}
			if(sides.indexOf('left') >= 0)
			{
				drawLine(x1, y1 - gaplen + height, x1, y1, gaplen);
			}
			if(sides.indexOf('bottom') >= 0)
			{
				drawLine(x1 + width, y1 + height, x1, y1 + height, gaplen);
			}
		}
	}
}