package {
import adt.Stack;
import components.bubbles.AdventureBubble;
import flash.display.DisplayObject;
import mx.core.IFlexDisplayObject;
import mx.core.IFlexDisplayObject;
import mx.managers.PopUpManager;
import screens.AdventurePopupBase;
public class PopUpManager
{
	private static var popUpList:Vector.<IFlexDisplayObject> = new Vector.<IFlexDisplayObject>();
	public static function addPopUp(window:IFlexDisplayObject,
	                                parent:DisplayObject,
	                                modal:Boolean = false,
	                                removeWithEscape:Boolean = false):void
	{
		if(removeWithEscape)
		{
			popUpList.push(window);
		}
		mx.managers.PopUpManager.addPopUp(window, parent, modal);
	}
	public static function removePopUp(popUp:IFlexDisplayObject):void
	{
		mx.managers.PopUpManager.removePopUp(popUp);
		// remove from popup list
		var index:int = popUpList.indexOf(popUp);
		if(index != -1)
		{
			popUpList.splice(index, 1);
		}
	}
	public static function bringToFront(popUp:IFlexDisplayObject):void
	{
		mx.managers.PopUpManager.bringToFront(popUp);
		// bring to front of popup list too
		var index:int = popUpList.indexOf(popUp);
		if(index != -1)
		{
			var item:IFlexDisplayObject = popUpList.splice(index, 1)[0];
			popUpList.push(item);
		}
	}
	public static function centerPopUp(popUp:IFlexDisplayObject):void
	{
		mx.managers.PopUpManager.centerPopUp(popUp);
	}
	public static function removeFirstPopUp():void
	{
		var topPopUp:* = popUpList.pop();
		if(topPopUp is AdventurePopupBase)
		{
			AdventurePopupBase(topPopUp).hide();
		}
		else if(topPopUp is AdventureBubble)
		{
			AdventureBubble(topPopUp).destroy();
		}
		else
		{
			mx.managers.PopUpManager.removePopUp(topPopUp);
		}
	}
}
}