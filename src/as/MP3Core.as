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
    import Consts;
    import State;

    public class MP3Core extends BaseCore {
        private var s:Sound;
        private var sc:SoundChannel;
        private var stf:SoundTransform;
        private var playerTimer:Timer;

        override public function init():void {
            super.init();
            if (ExternalInterface.available) {
                reset();
                stf = new SoundTransform(_volume / 100, 0);
                ExternalInterface.addCallback('load', load);
                ExternalInterface.addCallback('play', play);
                ExternalInterface.addCallback('pause', pause);
                ExternalInterface.addCallback('stop', stop);
                ExternalInterface.addCallback('getData', getData);
                ExternalInterface.addCallback('setData', setData);
                callJS(Consts.SWF_ON_LOAD);
            }
        }

        private function onLoadComplete(e:Event):void {
            _length = Math.ceil(s.length);
        }

        private function onProgress(e:ProgressEvent):void {
            setState(State.BUFFERING);
            if (!_bytesTotal) {
                _bytesTotal = s.bytesTotal;
            }
            _bytesLoaded = s.bytesLoaded;

            if (!_length) {
                // 估算的音频数据大小，精确值需要在onLoadComplete中获得。
                _length = Math.ceil(s.length / _bytesLoaded * _bytesTotal);
            }
            _loadedPct = Math.round(100 * _bytesLoaded / _bytesTotal) / 100;
        }

        override protected function onPlayComplete(e:Event = null):void {
            // 保证length和positionPct赋值正确。
            onPlayTimer();
            stop();
            setState(State.END);
        }

        private function onPlayTimer(e:TimerEvent = null):void {
            _position = sc.position;
            _positionPct = Math.round(100 * _position / _length) / 100;
        }

        override public function setVolume(v:uint):void {
            if (v < 0 || v > 100) {
                return;
            }
            _volume = v;
            stf.volume = v / 100;
            if (sc) {
                sc.soundTransform = stf;
            }
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

            this._url = url;
            setState(State.PREBUFFER);
            s.load(req, context);
        }

        override public function play(p:Number = 0):void {
            if (_state != State.PLAYING) {
                if (!p && _state == State.PAUSE) {
                    p = _pausePosition;
                }
                sc = s.play(p, 0, stf);
                sc.addEventListener(Event.SOUND_COMPLETE, onPlayComplete);
                setState(State.PLAYING);

                playerTimer = new Timer(Consts.TIMER_INTERVAL);
                playerTimer.addEventListener(TimerEvent.TIMER, onPlayTimer);
                playerTimer.start();
            }
        }

        override public function pause():void {
            stop(sc.position);
        }

        override public function stop(p:Number = 0):void {
            _pausePosition = p;
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
