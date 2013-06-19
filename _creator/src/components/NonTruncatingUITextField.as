package components
{
	import mx.core.UITextField;
	public class NonTruncatingUITextField extends UITextField
	{
		public function NonTruncatingUITextField()
		{
			super();
		}
		override public function truncateToFit(s:String = null):Boolean
		{
			return false;
		}
	}
}