package {
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

    import BaseCore;
    import Utils;
    import State;

    public class MP3Core extends BaseCore {
        private const TIMER_INTERVAL:int = 200;

        private var s:Sound;
        private var sc:SoundChannel;
        private var stf:SoundTransform;
        private var playerTimer:Timer;

        // JS回调
        private var JS_INSTANCE:String = '';
        private var SWF_ON_LOAD:String = '._swfOnLoad';
        private var SWF_ON_ERR:String = '._swfOnErr';
        private var SWF_ON_STATE_CHANGE:String = '._swfOnStateChange';

        private var volume:uint = 80;               // 音量(0-100)，默认80
        private var mute:Boolean = false;           // 静音状态，默认flase
        private var state:int = State.NOT_INIT;     // 播放状态
        private var muteVolume:uint;                // 静音时的音量
        private var url:String;                     // 外部文件地址
        private var length:uint;                    // 音频总长度(ms)
        private var position:uint;                  // 当前播放进度(ms)
        private var positionPct:Number;             // 播放进度百分比[0-1]
        private var pausePosition:Number;           // 暂停时的播放进度(ms)
        private var loadedPct:Number;               // 载入进度百分比[0-1]
        private var bytesTotal:uint;                // 外部文件总字节
        private var bytesLoaded:uint;               // 已载入字节

        private function onLoadComplete(e:Event):void {
            length = Math.ceil(s.length);
        }

        private function onProgress(e:ProgressEvent):void {
            setState(State.BUFFERING);
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
            setState(State.END);
        }

        private function onPlayTimer(e:TimerEvent = null):void {
            position = sc.position;
            positionPct = Math.round(100 * position / length) / 100;
        }

        override public function setVolume(v:uint):void {
            if (v < 0 || v > 100) {
                return;
            }
            volume = v;
            stf.volume = v / 100;
            if (sc) {
                sc.soundTransform = stf;
            }
        }

        public function handleErr(e:IOErrorEvent):void {
            onPlayComplete();
            callJS(SWF_ON_ERR, e);
        }

        override public function reset():void {
            // 及时做内存回收
            if (s) {
                s.removeEventListener(IOErrorEvent.IO_ERROR, handleErr);
                s.removeEventListener(Event.COMPLETE, onLoadComplete);
                s.removeEventListener(ProgressEvent.PROGRESS, onProgress);
                s = null;
            }
            super.reset();
        }

        override public function load(url:String):void {
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
                context:SoundLoaderContext = new SoundLoaderContext(getBufferTime(), true);

            this.url = url;
            setState(State.PREBUFFER);
            s.load(req, context);
        }

        override public function play(p:Number = 0):void {
            if (state != State.PLAYING) {
                if (!p && state == State.PAUSE) {
                    p = pausePosition;
                }
                sc = s.play(p, 0, stf);
                sc.addEventListener(Event.SOUND_COMPLETE, onPlayComplete);
                setState(State.PLAYING);

                playerTimer = new Timer(TIMER_INTERVAL);
                playerTimer.addEventListener(TimerEvent.TIMER, onPlayTimer);
                playerTimer.start();
            }
        }

        override public function pause():void {
            stop(sc.position);
        }

        override public function stop(p:Number = 0):void {
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
            setState(p && State.PAUSE || State.STOP);
        }
    }
}
