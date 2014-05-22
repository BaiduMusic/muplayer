package {
    import flash.display.Sprite;
    import flash.events.*;
    import flash.errors.IOError;
    import flash.external.ExternalInterface;
    import flash.media.Sound;
    import flash.media.SoundChannel;
    import flash.media.SoundTransform;
    import flash.media.SoundLoaderContext;
    import flash.net.URLRequest;
    import flash.system.Security;
    import flash.utils.Timer;

    public class MP3Core extends Sprite {
        // 播放状态
        private const S_NOT_INIT:int = -1;
        private const S_PREBUFFER:int = 1;
        private const S_BUFFERING:int = 2;
        private const S_PLAYING:int = 3;
        private const S_PAUSE:int = 4;
        private const S_STOP:int = 5;
        private const S_END:int = 6;

        // 播放进度相关的计时器
        private const TIMER_INTERVAL:int = 200;

        private var STATES:Array = new Array(
            S_PREBUFFER, S_BUFFERING, S_PLAYING, S_PAUSE, S_STOP, S_END
        );

        private var s:Sound;
        private var sc:SoundChannel;
        private var stf:SoundTransform;
        private var playerTimer:Timer;

        // JS回调
        private var JS_INSTANCE:String = '';
        private var SWF_ON_LOAD:String = '._swfOnLoad';
        private var SWF_ON_ERR:String = '._swfOnErr';
        private var SWF_ON_STATE_CHANGE:String = '._swfOnStateChange';

        private var volume:int = 80;            // 音量(0-100)，默认80
        private var mute:Boolean = false;       // 静音状态，默认flase
        private var state:int = S_NOT_INIT;     // 播放状态
        private var muteVolume:int;             // 静音时的音量
        private var url:String;                 // 外部文件地址
        private var length:uint;                // 音频总长度(ms)
        private var position:uint;              // 当前播放进度(ms)
        private var positionPct:Number;         // 播放进度百分比[0-1]
        private var pausePosition:Number;       // 暂停时的播放进度(ms)
        private var loadedPct:Number;           // 载入进度百分比[0-1]
        private var bytesTotal:uint;            // 外部文件总字节
        private var bytesLoaded:uint;           // 已载入字节

        // 最小缓冲时间(ms)
        // MP3 数据保留在Sound对象缓冲区中的最小毫秒数。
        // 在开始回放以及在网络中断后继续回放之前，Sound 对
        // 象将一直等待直至至少拥有这一数量的数据为止。
        // 默认值为1000毫秒。
        private var bufferTime:Number = 5000;

        public function MP3Core() {
            this.addEventListener(Event.ENTER_FRAME, checkStage);
        }

        public function init():void {
            Security.allowDomain('*');
            Security.allowInsecureDomain('*');
            loadFlashVars(loaderInfo.parameters);
            if (ExternalInterface.available) {
                reset();
                stf = new SoundTransform(volume / 100, 0);
                ExternalInterface.addCallback('load', load);
                ExternalInterface.addCallback('play', play);
                ExternalInterface.addCallback('pause', pause);
                ExternalInterface.addCallback('stop', stop);
                ExternalInterface.addCallback('getData', getData);
                ExternalInterface.addCallback('setData', setData);
                callJS(SWF_ON_LOAD);
            }
        }

        public function callJS(fn:String, data:Object = undefined):void {
            ExternalInterface.call(JS_INSTANCE + fn, data);
        }

        private function log(msg:String):void {
            ExternalInterface.call('console.log', 'fmp: ' + msg);
        }

        private function checkStage(e:Event = null):void {
            if (stage.stageWidth > 0) {
                this.removeEventListener(Event.ENTER_FRAME, checkStage);
                init();
            }
        }

        private function loadFlashVars(p:Object):void {
            JS_INSTANCE = p['_instanceName'];
            setBufferTime(p['_buffertime'] || bufferTime);
        }

        private function onLoadComplete(e:Event):void {
            length = Math.ceil(s.length);
        }

        private function onProgress(e:ProgressEvent):void {
            setState(S_BUFFERING);
            if (!bytesTotal) {
                bytesTotal = s.bytesTotal;
            }
            bytesLoaded = s.bytesLoaded;

            if (!length) {
                // 估算的音频数据大小，精确值需要在onLoadComplete中获得。
                length = Math.ceil(s.length / bytesLoaded * bytesTotal);
            }
            loadedPct = Math.round(100 * bytesLoaded / bytesTotal) / 100;
        }

        private function onPlayComplete(e:Event = null):void {
            // 保证length和positionPct赋值正确。
            onPlayTimer();
            stop();
            setState(S_END);
        }

        private function onPlayTimer(e:TimerEvent = null):void {
            position = sc.position;
            positionPct = Math.round(100 * position / length) / 100;
        }

        public function getState():int {
            return state;
        }

        public function setState(st:int):void {
            if (state != st && STATES.indexOf(st) != -1) {
                state = st;
                callJS(SWF_ON_STATE_CHANGE, st);
            }
        }

        public function getBufferTime():Number {
            return bufferTime;
        }

        public function setBufferTime(bt:Number):void {
            bufferTime = bt;
        }

        public function setMute(m:Boolean):void {
            if (m) {
                muteVolume = volume;
                setVolume(0);
            } else {
                setVolume(muteVolume);
            }
            mute = m;
        }

        public function getMute():Boolean {
            return mute;
        }

        public function setVolume(v:int):void {
            if (v < 0 || v > 100) {
                return;
            }
            volume = v;
            stf.volume = v / 100;
            if (sc) {
                sc.soundTransform = stf;
            }
        }

        public function getUrl():String {
            return url;
        }

        public function getPosition():uint {
            return position;
        }

        // positionPct和loadedPct都在JS层按需获取，不在
        // AS层主动派发，这样简化逻辑，节省事件开销。
        public function getPositionPct():Number {
            return positionPct;
        }

        public function getLoadedPct():Number {
            return loadedPct;
        }

        public function getLength():uint {
            return length;
        }

        public function getBytesTotal():uint {
            return bytesTotal;
        }

        public function getBytesLoaded():uint {
            return bytesLoaded;
        }

        public function getData(k:String):* {
            var fn:String = 'get' + k.substr(0, 1).toUpperCase() + k.slice(1);
            if (this[fn]) {
                return this[fn]();
            }
        }

        public function setData(k:String, v:*):* {
            var fn:String = 'set' + k.substr(0, 1).toUpperCase() + k.slice(1);
            if (this[fn]) {
                return this[fn](v);
            }
        }

        public function handleErr(e:IOErrorEvent):void {
            onPlayComplete();
            callJS(SWF_ON_ERR, e);
        }

        public function reset():void {
            // 及时做内存回收
            if (s) {
                s.removeEventListener(IOErrorEvent.IO_ERROR, handleErr);
                s.removeEventListener(Event.COMPLETE, onLoadComplete);
                s.removeEventListener(ProgressEvent.PROGRESS, onProgress);
                s = null;
            }
            url = '';
            length = 0;
            position = 0;
            positionPct = 0;
            loadedPct = 0;
            bytesTotal = 0;
            bytesLoaded = 0;
        }

        public function load(url:String):void {
            stop();

            try {
                s && s.close();
            } catch (err:IOError) {
                // Occurs if the file is either yet to be opened or has finished downloading.
            } finally {
                reset();
            }

            s = new Sound();
            s.addEventListener(IOErrorEvent.IO_ERROR, handleErr);
            s.addEventListener(Event.COMPLETE, onLoadComplete);
            s.addEventListener(ProgressEvent.PROGRESS, onProgress);

            var req:URLRequest = new URLRequest(url),
                context:SoundLoaderContext = new SoundLoaderContext(bufferTime, true);

            this.url = url;
            setState(S_PREBUFFER);
            s.load(req, context);
        }

        public function play(p:Number = 0):void {
            if (state != S_PLAYING) {
                if (!p && state == S_PAUSE) {
                    p = pausePosition;
                }
                sc = s.play(p, 0, stf);
                sc.addEventListener(Event.SOUND_COMPLETE, onPlayComplete);
                setState(S_PLAYING);

                playerTimer = new Timer(TIMER_INTERVAL);
                playerTimer.addEventListener(TimerEvent.TIMER, onPlayTimer);
                playerTimer.start();
            }
        }

        public function pause():void {
            stop(sc.position);
        }

        public function stop(p:Number = 0):void {
            pausePosition = p;
            // 判断sc是否存在是因为sc在play方法调用时才被延迟初始化
            if (sc) {
                sc.stop();
            }
            if (playerTimer) {
                playerTimer.removeEventListener(TimerEvent.TIMER, onPlayTimer);
                playerTimer.stop();
                playerTimer = null;
            }
            setState(p && S_PAUSE || S_STOP);
        }
    }
}
