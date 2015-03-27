package
{
	import cn.wecoding.consts.Font;
	import cn.wecoding.evt.ViewerEvt;
	import cn.wecoding.utils.StageReference;
	import cn.wecoding.utils.UIUtil;
	import cn.wecoding.v.Viewer;
	
	import com.greensock.TweenLite;
	
	import flash.desktop.ClipboardFormats;
	import flash.desktop.NativeDragManager;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.NativeDragEvent;
	import flash.filesystem.File;
	import flash.text.TextField;
	import flash.text.TextFormat;
	
	/**
	 * 显示视频的metadta 
	 * @author yangq1990
	 * 
	 */	
	[SWF(width=1024,height=768)]
	public class Main extends BaseInitView
	{
		/** 提示 **/
		private var _hint:TextField;
		/** 背景可见元素，拖放的时候组成监测区域 **/
		private var _back:Sprite;
		
		private var _tween1:TweenLite;
		private var _tween2:TweenLite;		
		/** viewer数量 **/
		private var _viewerCount:int = 0;
		private var _hasCenterViewer:Boolean = false;
		

		public function Main()
		{
			super();		
		}
		
		override protected function init():void
		{
			super.init();
			
			_hint = new TextField();
			_hint.defaultTextFormat = new TextFormat(Font.YAHEI, 56, 0x000000);
		
			if(NativeDragManager.isSupported)
			{
				_hint.text = "拖放文件到此处";
				
				new StageReference(this);
				
				this.stage.addEventListener(ViewerEvt.REMOVE, onRemoveSelectedViewer);			
				this.stage.addEventListener(ViewerEvt.ADDTO_TOP, onAddSelectedViewerToTop);
				
				_back = new Sprite();
				var g:Graphics = _back.graphics;
				g.beginFill(0x000000, 0.5);
				g.drawRect(0,0,stage.stageWidth,stage.stageHeight);
				g.endFill();
				this.addChild(_back);				
				_back.addEventListener(NativeDragEvent.NATIVE_DRAG_ENTER, onNativeDragEnter);
				_back.addEventListener(NativeDragEvent.NATIVE_DRAG_DROP, onNativeDragDrop);
			}
			else
			{
				_hint.text = '不支持拖放';
			}		
			
			UIUtil.adjustTFWidthAndHeight(_hint);
			_hint.x = (this.stage.stageWidth - _hint.textWidth) * 0.5;
			_hint.y = (this.stage.stageHeight * 0.5  - _hint.textHeight) ;
			addChild(_hint);
		}
		
		/** 移除选中的viewer **/
		private function onRemoveSelectedViewer(evt:ViewerEvt):void
		{
			var viewer:Sprite = this.getChildByName(evt.name) as Sprite;
			if(viewer != null)
			{
				var index:int = this.getChildIndex(viewer);
				if(index == this.numChildren-1) //移除了top viewer
				{
					var temp:Sprite = this.getChildAt(index-1) as Sprite;
					if(temp != null && temp is Viewer)
					{
						var startX:Number = temp.x;
						var startY:Number = temp.y;
						temp.x = (StageReference.stage.stageWidth - temp.width) * 0.5;
						temp.y = 0;
						TweenLite.from(temp, 0.3, {x:startX, y:startY, alpha:0.3});
					}
				}
				this.removeChild(viewer);
				viewer = null;
				_viewerCount -= 1;
			}
			
			//所有的viewer都移除后可以重新拖放文件添加
			if(this.numChildren == 2)
			{
				_hint.visible = true;
				_viewerCount = 0;
				_hasCenterViewer = false;
			}
		}
		
		/** 添加选中的viewer到最上层 **/
		private function onAddSelectedViewerToTop(evt:ViewerEvt):void
		{
			if(this.numChildren > 3)
			{
				//点击选中的viewer
				var selectedViewer:Sprite = this.getChildByName(evt.name) as Sprite;
				var index1:int = this.getChildIndex(selectedViewer);
				var x1:Number = selectedViewer.x;
				var y1:Number = selectedViewer.y;
				var centerX:Number = (StageReference.stage.stageWidth - selectedViewer.width) * 0.5; 
				if(index1 == this.numChildren - 1) //已经在最上层
				{
					if(x1 != centerX)
					{
						selectedViewer.x = centerX;
						selectedViewer.y = 0;
					}
					return;
				}								
				
				//当前位于最上层居中现实的viewer
				var currentTopViewer:Sprite = this.getChildAt(this.numChildren-1) as Sprite;
				var index2:int = this.numChildren - 1;				
				
				if(_tween1 != null)
				{
					TweenLite.killTweensOf(_tween1);
					_tween1 = null;
				}
				
				if(_tween2 != null)
				{
					TweenLite.killTweensOf(_tween2);
					_tween2 = null;
				}
				
				this.setChildIndex(selectedViewer, index2);
				this.setChildIndex(currentTopViewer, index1);		
				
				_tween1 = TweenLite.to(selectedViewer, 0.3, {x:centerX, y:0});
				_tween2  =TweenLite.to(currentTopViewer, 0.3, {x:x1, y:y1});
			}
			
		}
		
		/** 拖放文件进入AIR程序 **/
		private function onNativeDragEnter(evt:NativeDragEvent):void
		{
			if(evt.clipboard.hasFormat(ClipboardFormats.FILE_LIST_FORMAT))
			{
				NativeDragManager.acceptDragDrop(_back);
			}		
		}
		
		/** 拖放结束 **/
		private function onNativeDragDrop(evt:NativeDragEvent):void
		{
			var dropfiles:Array = evt.clipboard.getData(ClipboardFormats.FILE_LIST_FORMAT) as Array;
			
			if(dropfiles == null)
			{
				return;
			}
			
			_hint.visible = false;
			var viewer:Viewer;
			var len:int = dropfiles.length; //选中文件的数量
			
			var currentTopViewer:Sprite;
			if(this.numChildren > 2)
			{
				 currentTopViewer = this.getChildAt(this.numChildren-1) as Sprite;
			}
			
			var file:File;
			for(var i:int = 0; i < len; i++)
			{
				file = dropfiles[i] as File;
				viewer = new Viewer();
				viewer.name = file.name;
				viewer.detect(file);				
				viewer.x = (i+_viewerCount) * 40;
				viewer.y = StageReference.stage.stageHeight * 0.5 -  (i+_viewerCount) * 40;
				addChildAt(viewer, 2 + i+_viewerCount);
				
				if(i == len - 1 && !_hasCenterViewer) //最后一个元素居中
				{
					viewer.x = (StageReference.stage.stageWidth - viewer.width) * 0.5;
					viewer.y = 0;
					_hasCenterViewer = true;
				}
			}
			
			_viewerCount += len;
			if(currentTopViewer)
			{
				this.setChildIndex(currentTopViewer, this.numChildren-1);
			}			
		}
	}
}