package {
    import flash.display.Sprite;
    import flash.display.StageAlign;
    import flash.display.StageScaleMode;
    import flash.events.*;
    import flash.media.SoundTransform;
    import flash.system.Security;
    import flash.utils.Timer;

    public class BaseCore extends Sprite implements IEngine {
        // JS回调
        private var jsInstance:String = '';
        private var canPlayThrough:Boolean = false;

        protected var playerTimer:Timer = new Timer(Consts.TIMER_INTERVAL);
        protected var stf:SoundTransform;

        // 实例属性
        protected var _volume:uint = 80;               // 音量(0-100)，默认80
        protected var _mute:Boolean = false;           // 静音状态，默认flase
        protected var _state:int = State.STOP;         // 播放状态
        protected var _muteVolume:uint;                // 静音时的音量
        protected var _url:String;                     // 外部文件地址
        protected var _length:uint;                    // 音频总长度(ms)
        protected var _position:uint = 0;              // 当前播放进度(ms)
        protected var _loadedPct:Number;               // 载入进度百分比[0-1]
        protected var _positionPct:Number;             // 播放进度百分比[0-1]
        protected var _pausePosition:Number;           // 暂停时的播放进度(ms)
        protected var _bytesTotal:uint;                // 外部文件总字节
        protected var _bytesLoaded:uint;               // 已载入字节

        // 最小缓冲时间(ms)
        // MP3 数据保留在Sound对象缓冲区中的最小毫秒数。
        // 在开始回放以及在网络中断后继续回放之前，Sound 对
        // 象将一直等待直至至少拥有这一数量的数据为止。
        // 默认值为1000毫秒。
        private var _bufferTime:uint = 5000;

        protected function updatePostion(pos:uint = 0):void {
            var st:int = getState();

            // 页面因网速较慢导致缓冲不够播放停止的情况
            if (st === State.PREBUFFER && _position === pos) {
                setState(State.BUFFERING);
            } else if (_position < pos) {
                setState(State.PLAYING);
            }

            _position = pos;

            if (_position > _length) {
                _length = _position;
            }
            _positionPct = Math.round(100 * _position / _length) / 100;
        }

        public function BaseCore() {
            // http://www.markledford.com/blog/2008/08/13/why-some-as3-swfs-work-stand-alone-but-fail-to-load-into-other-swfs/
            if (stage) {
                init();
            } else {
                addEventListener(Event.ADDED_TO_STAGE, init);
            }
        }

        public function init(e:Event = null):void {
            removeEventListener(Event.ADDED_TO_STAGE, init);
            stage.align = StageAlign.TOP_LEFT;
            stage.scaleMode = StageScaleMode.NO_SCALE;
            Security.allowDomain('*');
            Security.allowInsecureDomain('*');
            loadFlashVars(loaderInfo.parameters);
            stf = new SoundTransform(_volume / 100, 0);
            playerTimer.addEventListener(TimerEvent.TIMER, onPlayTimer);
        }

        protected function callJS(fn:String, data:Object = undefined):void {
            Utils.callJS(jsInstance + fn, data);
        }

        protected function callOnLoad():void {
            // 借鉴自SoundManager2，防止ActionScript3的TypeError: Error #1009
            // https://github.com/scottschiller/SoundManager2/blob/master/src/SoundManager2_AS3.as
            // call after delay, to be safe (ensure callbacks are registered by the time JS is called below)
            var timer:Timer = new Timer(500);
            timer.addEventListener(TimerEvent.TIMER, function():void {
                timer.reset();
                callJS(Consts.SWF_ON_LOAD);
            });
            timer.start();
        }

        protected function loadFlashVars(p:Object):void {
            jsInstance = escape(p['_instanceName']);
            if (p['_buffertime']) {
                _bufferTime = ~~p['_buffertime'];
            }
        }

        protected function onPlayComplete(e:Event = null):void {
            // 保证length和positionPct赋值正确。
            onPlayTimer();
            f_stop();
            setState(State.END);
        }

        protected function onPlayTimer(e:TimerEvent = null):void {}

        protected function handleErr(e:* = null):void {
            callJS(Consts.SWF_ON_ERR, e);
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
            return _state;
        }

        public function setState(st:int):void {
            if (_state !== st && State.validate(st)) {
                if (canPlayThrough && (st === State.PREBUFFER || st === State.BUFFERING)) {
                    return;
                }

                if (st === State.CANPLAYTHROUGH) {
                    canPlayThrough = true;
                }

                _state = st;
                callJS(Consts.SWF_ON_STATE_CHANGE, st);
            }
        }

        public function getBufferTime():uint {
            return _bufferTime;
        }

        public function getMute():Boolean {
            return _mute;
        }

        public function setMute(m:Boolean):void {
            if (m) {
                _muteVolume = _volume;
                setVolume(0);
            } else {
                setVolume(_muteVolume || _volume);
            }
            _mute = m;
        }

        public function getVolume():uint {
            return _volume;
        }

        public function setVolume(v:uint):Boolean {
            if (v < 0 || v > 100) {
                return false;
            }
            _volume = v;
            stf.volume = v / 100;
            return true;
        }

        public function getUrl():String {
            return _url;
        }

        public function getLength():uint {
            return _length;
        }

        public function getPosition():uint {
            return _position;
        }

        public function getLoadedPct():Number {
            return _loadedPct;
        }

        // positionPct和loadedPct都在JS层按需获取，不在
        // AS层主动派发，这样简化逻辑，节省事件开销。
        public function getPositionPct():Number {
            return _positionPct;
        }

        public function getBytesTotal():uint {
            return _bytesTotal;
        }

        public function getBytesLoaded():uint {
            return _bytesLoaded;
        }

        public function reset():void {
            _url = '';
            _length = 0;
            _position = 0;
            _loadedPct = 0;
            _positionPct = 0;
            _pausePosition = 0;
            _bytesTotal = 0;
            _bytesLoaded = 0;
        }

        public function f_load(url:String):void {}

        public function f_play(p:Number = 0):void {
            playerTimer.start();
            setState(State.PREBUFFER);
        }

        public function f_pause():void {}

        public function f_stop(p:Number = -1):void {
            playerTimer.stop();
            if (p === -1) {
                _position = 0;
                _pausePosition = 0;
                setState(State.STOP);
            } else {
                _pausePosition = p;
                setState(State.PAUSE);
            }
        }
    }
}
