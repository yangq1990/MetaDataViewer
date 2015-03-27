package cn.wecoding.evt
{
	import flash.events.Event;
	
	public class ViewerEvt extends Event
	{
		public static const REMOVE:String = "remove";
		
		public static const ADDTO_TOP:String = "add_to_top";
		
		public var name:String;
		
		public function ViewerEvt(type:String, name:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			this.name = name;
		}
		
		override public function clone():Event
		{
			return new ViewerEvt(type, name);
		}
	}
}