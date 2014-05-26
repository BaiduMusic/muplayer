package {
    import flash.display.Sprite;
    import flash.events.*;
    import flash.errors.IOError;
    import flash.external.ExternalInterface;
    import flash.media.SoundTransform;
    import flash.system.Security;

    import Utils;
    import State;

    public class BaseCore extends Sprite implements IEngine {
        private var stf:SoundTransform;

        // JS回调
        private var JS_INSTANCE:String = '';
        private const SWF_ON_LOAD:String = '._swfOnLoad';
        private const SWF_ON_ERR:String = '._swfOnErr';
        private const SWF_ON_STATE_CHANGE:String = '._swfOnStateChange';

        private var volume:uint = 80;               // 音量(0-100)，默认80
        private var mute:Boolean = false;           // 静音状态，默认flase
        private var state:int = State.NOT_INIT;     // 播放状态
        private var muteVolume:uint;                // 静音时的音量
        private var url:String;                     // 外部文件地址
        private var length:uint;                    // 音频总长度(ms)
        private var position:uint;                  // 当前播放进度(ms)
        private var loadedPct:Number;               // 载入进度百分比[0-1]
        private var positionPct:Number;             // 播放进度百分比[0-1]
        private var pausePosition:Number;           // 暂停时的播放进度(ms)
        private var bytesTotal:uint;                // 外部文件总字节
        private var bytesLoaded:uint;               // 已载入字节

        // 最小缓冲时间(ms)
        // MP3 数据保留在Sound对象缓冲区中的最小毫秒数。
        // 在开始回放以及在网络中断后继续回放之前，Sound 对
        // 象将一直等待直至至少拥有这一数量的数据为止。
        // 默认值为1000毫秒。
        private var bufferTime:Number = 5000;

        public function BaseCore() {
            Utils.checkStage(this, 'init');
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

        protected function callJS(fn:String, data:Object = undefined):void {
            Utils.callJS(JS_INSTANCE + fn, data);
        }

        protected function loadFlashVars(p:Object):void {
            JS_INSTANCE = p['_instanceName'];
            setBufferTime(p['_buffertime'] || bufferTime);
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

        public function getState():int {
            return state;
        }

        public function setState(st:int):void {
            if (state != st && State.validate(st)) {
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

        public function getMute():Boolean {
            return mute;
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

        public function getVolume():uint {
            return volume;
        }

        public function setVolume(v:uint):void {}

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

        public function reset():void {
            url = '';
            length = 0;
            position = 0;
            loadedPct = 0;
            positionPct = 0;
            pausePosition = 0;
            bytesTotal = 0;
            bytesLoaded = 0;
        }

        public function load(url:String):void {}

        public function play(p:Number = 0):void {}

        public function pause():void {}

        public function stop(p:Number = 0):void {}
    }
}
