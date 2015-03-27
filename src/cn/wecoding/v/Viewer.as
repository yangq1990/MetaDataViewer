package cn.wecoding.v
{
	import cn.wecoding.consts.Font;
	import cn.wecoding.evt.ViewerEvt;
	import cn.wecoding.utils.MetadataUtil;
	import cn.wecoding.utils.ShapeFactory;
	import cn.wecoding.utils.StageReference;
	import cn.wecoding.v.ui.Button;
	
	import fl.controls.TextArea;
	
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.IOErrorEvent;
	import flash.events.MouseEvent;
	import flash.events.NetStatusEvent;
	import flash.events.SecurityErrorEvent;
	import flash.filesystem.File;
	import flash.filters.GlowFilter;
	import flash.geom.Rectangle;
	import flash.media.SoundTransform;
	import flash.media.Video;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.system.System;
	import flash.text.TextField;
	import flash.text.TextFormat;
	
	/**
	 * 视频metadata的查看器 
	 * @author yangq1990
	 * 
	 */	
	public class Viewer extends Sprite
	{
		private var _nc:NetConnection;
		private var _stream:NetStream;
		private var _video:Video;
		/** 视频容器 **/
		private var _videoContainer:Sprite;
		private var _metadata:TextArea;		
		/** 复制metadata button **/
		private var _copyBtn:Button;		
		/** 关闭button **/
		protected var _closeBtn:Sprite;
		private var _defaultShape:Shape;
		private var _overShape:Shape;
		
		public function Viewer()
		{
			super();
		}
		
		/**
		 * 检测视频 
		 * @param file
		 * 
		 */		
		public function detect(file:File):void
		{	
			_nc = new NetConnection();
			_nc.client = this;
			_nc.connect(null);
			
			_videoContainer = new Sprite();
			_videoContainer.addEventListener(MouseEvent.CLICK, onClickVideo);
			addChild(_videoContainer);
			
			_video = new Video();
			_video.smoothing = true;
			_videoContainer.addChild(_video);
			
			_copyBtn = new Button(_videoContainer.width, 48, 0x19a97b, 1, true);
			_copyBtn.label = "复制MetaData到剪贴板";
			_copyBtn.registerHandler(copyMetaData);
			_copyBtn.x = _videoContainer.x;
			_copyBtn.y = _videoContainer.y + _videoContainer.height + 10;
			addChild(_copyBtn);			
			_copyBtn.visible = false;
		
			_metadata = new TextArea();
			_metadata.setStyle("textFormat", new TextFormat(Font.YAHEI, 14, 0x000000));
			_metadata.editable = false;
			_metadata.x = _videoContainer.x + _videoContainer.width + 10;
			_metadata.width = 300;
			_metadata.height = StageReference.stage.stageHeight;
			addChild(_metadata);
			
			drawCloseBtn();
			addChild(_closeBtn);
			_closeBtn.x = _videoContainer.x + _videoContainer.width - _closeBtn.width;
			_closeBtn.y =  _closeBtn.height;			
			
			_stream = new NetStream(_nc);
			_stream.client = this;
			_stream.addEventListener(IOErrorEvent.IO_ERROR, onIOError);
			_stream.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError);
			_stream.addEventListener(NetStatusEvent.NET_STATUS, onNetStatus);
			_stream.play(file.nativePath);
			
			_video.attachNetStream(_stream);
			
			var g:Graphics = this.graphics;
			g.beginFill(0x333333);
			g.drawRect(0, 0, this.width, this.height);
			g.endFill();
			
			this.addEventListener(MouseEvent.CLICK, onClick);			
		}
		
		/** 点击视频切换静音 **/
		private function onClickVideo(evt:MouseEvent):void
		{
			evt.stopPropagation();
			if(_stream)
			{
				var value:int = _stream.soundTransform.volume == 0 ? 1 : 0;
				_stream.soundTransform = new SoundTransform(value);
			}		
		}
		
		/** 点击当前viewer后添加到最上层 **/
		private function onClick(evt:MouseEvent):void
		{
			StageReference.stage.dispatchEvent(new ViewerEvt(ViewerEvt.ADDTO_TOP, this.name)); 
		}
		
		private function copyMetaData():void
		{
			System.setClipboard(_metadata.text);
			_copyBtn.label = "已复制！！！";
		}
				
		
		public function onMetaData(info:Object):void
		{
			var keyframesStr:String;
			if (info['seekpoints']) 
			{
				_metadata.appendText('文件类型 : mp4\n');
				keyframesStr = MetadataUtil.convertSeekpoints2String(info['seekpoints']);
			}
			else if(info['keyframes'])
			{
				_metadata.appendText('文件类型 : flv\n');
				keyframesStr = MetadataUtil.convertKeyframes2String(info['keyframes']);
			}
			
			for(var item:* in info)
			{
				if(item == "audiosize" || item == "filesize" || item == "datasize" || item == "videosize")
				{
					_metadata.appendText(item + ' : ' + MetadataUtil.byte2MB(info[item]) + '\n');
				}
				else if(item != "seekpoints" && item != "keyframes")
				{
					_metadata.appendText(item + ' : ' + info[item] + '\n');
				}				
			}
			
			_metadata.appendText("---------------------\n");
			_metadata.appendText(keyframesStr);
			
		}
		
		public function onPlayStatus(info:Object):void
		{
			
		}
		
		public function onXMPData(info:Object):void
		{
			
		}
		
		private function onIOError(evt:IOErrorEvent):void
		{
			trace('ioerror');
		}
		
		private function onSecurityError(evt:SecurityErrorEvent):void
		{
			trace('securityerror');	
		}
		
		private function onNetStatus(evt:NetStatusEvent):void
		{
			trace(evt.info.code);
			switch(evt.info.code)
			{
				case 'NetStream.Play.StreamNotFound':
					_metadata.setStyle('textFormat', new TextFormat(Font.YAHEI, 26, 0xff0000)); 
					_metadata.text = "无法播放视频";
					break;
				case 'NetStream.Play.Start':
					_copyBtn.visible = true;
					_stream.soundTransform = new SoundTransform(0);
					break;				
				default:
					break;
			}
		}
		
		/**
		 * 画关闭按钮 
		 * 
		 */		
		protected function drawCloseBtn():void
		{
			_defaultShape = ShapeFactory.getShapeByColor(0x333333);
			_defaultShape.name = "default";
			
			_overShape = ShapeFactory.getShapeByColor(0x19a97b);
			_overShape.name = "over";
			
			_closeBtn = new Sprite();
			_closeBtn.mouseChildren = false;
			_closeBtn.buttonMode = true;
			_closeBtn.name = "close";
			_closeBtn.addChild(_overShape);
			_overShape.visible = false;
			_closeBtn.addChild(_defaultShape);			
			_closeBtn.addEventListener(MouseEvent.CLICK, onClickCloseBtn);	
			_closeBtn.filters = [new GlowFilter(0x666666,1,8.0,8.0)];	
			_closeBtn.addEventListener(MouseEvent.MOUSE_OVER, onMouseOverCloseBtn);
			_closeBtn.addEventListener(MouseEvent.MOUSE_OUT, onMouseOutCloseBtn);
		}
		
		private function onMouseOverCloseBtn(evt:MouseEvent):void
		{
			evt.stopPropagation();
			_overShape.visible = true;		
			_defaultShape.visible = false;
		}
		
		private function onMouseOutCloseBtn(evt:MouseEvent):void
		{
			evt.stopPropagation();
			_overShape.visible = false;
			_defaultShape.visible = true;
		}
		
		protected function onClickCloseBtn(evt:MouseEvent):void
		{			
			evt.stopPropagation();
			
			//释放占用的资源
			_video.attachNetStream(null);
			
			if(_stream)
			{
				_stream.close();
				_stream.removeEventListener(IOErrorEvent.IO_ERROR, onIOError);
				_stream.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError);
				_stream.removeEventListener(NetStatusEvent.NET_STATUS, onNetStatus);
				_stream = null;
			}
			
			if(_nc)
			{				
				_nc.close();
				_nc = null;	
			}
			
			StageReference.stage.dispatchEvent(new ViewerEvt(ViewerEvt.REMOVE, this.name)); 
		}
		
		override public function get width():Number
		{
			return _video.x + _video.width + 10 + _metadata.width;
		}
		
		override public function get height():Number
		{
			return StageReference.stage.stageHeight;
		}
	}
}