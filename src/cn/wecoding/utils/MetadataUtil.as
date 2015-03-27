package cn.wecoding.utils
{
	/**
	 * 处理视频metadata的工具类 
	 * @author yatsen_yang
	 * 
	 */	
	public class MetadataUtil
	{
		public function MetadataUtil()
		{
		}
		
		/**
		 *  
		 * @param data object with keyframe times and positions
		 * @param sec 拖动的时间点
		 * @param tme true 返回离拖动点最近的关键帧的时间点;false 返回离拖动点最近的关键帧的字节偏移量
		 * @return 
		 * 
		 */		
		public static function getOffset(data:Object, sec:Number, tme:Boolean=false):Number 
		{
			if (!data) 
			{
				return 0;
			}
			
			for (var i:Number = 0; i < data.times.length - 1; i++) 
			{
				if (data.times[i] <= sec && data.times[i + 1] >= sec) 
				{
					break;
				}
			}
			
			if(!tme)
			{
				return data.filepositions[i];
			}
			else
			{
				return data.times[i];
			}
		}
		
		/**
		 * 字节B转换为等量的MB 
		 * @param size
		 * @param precision 精度，默认为1，即小数点后保留1个数字
		 * @return 
		 * 
		 */		
		public static function byte2MB(size:Number, precision:int=1):String
		{			
			if(size < 1024)
			{
				return int(size) + "B";
			}				
			
			var str:String = (size / 1024 / 1024).toString();
			if(str.indexOf(".") != -1)
			{
				var arr:Array = str.split(".");
				if(int(arr[0]) == 0)
				{
					return arr[0] + "." + arr[1].slice(0, 2) + "MB";					
				}
				else
				{
					if(arr[1].length <= precision)
						return str + "MB";
					else
						return arr[0] + "." + arr[1].slice(0, precision) + "MB";
				}								
			}
			else
			{
				return size + "MB";	
			}		
		}
		
		
		public static function convertSeekpoints2String(dat:Object):String 
		{
			var result:String = "";
			for (var j:String in dat)
			{
				result += ("time: " + Number(dat[j]['time']) + "\t offset: " + Number(dat[j]['offset'] + "\n"));
			}
			return result;
		}
		
		public static function convertKeyframes2String(keyframes:Object):String
		{
			var result:String = "";
			var len:int = keyframes.times.length;
			for(var i:int = 0; i < len; i++)
			{
				result += ("time: " + keyframes.times[i] + "\t offset: " + keyframes.filepositions[i] + "\n");
			}
			return result;
		}
	}
}