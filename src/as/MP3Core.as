package {
    import flash.events.*;
    import flash.external.ExternalInterface;
    import flash.media.Sound;
    import flash.media.SoundChannel;
    import flash.media.SoundTransform;
    import flash.media.SoundLoaderContext;
    import flash.net.URLRequest;

    public class MP3Core extends BaseCore {
        private var s:Sound = new Sound();
        private var sc:SoundChannel = new SoundChannel();
        private var isPlaying:Boolean;

        override public function init(e:Event = null):void {
            super.init();
            if (ExternalInterface.available) {
                reset();
                ExternalInterface.addCallback('f_load', f_load);
                ExternalInterface.addCallback('f_play', f_play);
                ExternalInterface.addCallback('f_pause', f_pause);
                ExternalInterface.addCallback('f_stop', f_stop);
                ExternalInterface.addCallback('getData', getData);
                ExternalInterface.addCallback('setData', setData);
                Utils.log('onLoad');
                callOnLoad();
            }
        }

        private function onLoadComplete(e:Event):void {
            _length = Math.ceil(s.length);
            setState(State.CANPLAYTHROUGH);
        }

        private function onProgress(e:ProgressEvent):void {
            if (getState() !== State.PLAYING) {
                setState(State.BUFFERING);
            }

            if (!_bytesTotal) {
                _bytesTotal = s.bytesTotal;
            }
            _bytesLoaded = s.bytesLoaded;
            _loadedPct = Math.round(100 * _bytesLoaded / _bytesTotal) / 100;

            if (!_length) {
                // 估算的音频时长，精确值需要在onLoadComplete中获得。
                _length = Math.ceil(s.length / _bytesLoaded * _bytesTotal);
            }
        }

        override protected function onPlayTimer(e:TimerEvent = null):void {
            var st:int = getState(),
                pos:uint = sc.position;

            // 页面因网速较慢导致缓冲不够播放停止的情况
            if (st === State.PLAYING && _position === pos) {
                setState(State.PREBUFFER);
            } else if (st !== State.PLAYING && _position < pos) {
                setState(st === State.PREBUFFER && State.BUFFERING || State.PLAYING);
            }

            _position = sc.position;

            if (_position > _length) {
                _length = _position;
            }

            _positionPct = Math.round(100 * _position / _length) / 100;
        }

        override public function setVolume(v:uint):Boolean {
            var success:Boolean = super.setVolume(v);
            if (success && sc) {
                sc.soundTransform = stf;
            }
            return success;
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

        override public function f_load(url:String):void {
            Utils.log('f_load: ' + url);
            f_stop();

            try {
                s && s.close();
            } catch (err:Error) {
                // Occurs if the file is either yet to be opened or has finished downloading.
            } finally {
                reset();
            }

            s = new Sound();
            s.addEventListener(IOErrorEvent.IO_ERROR, handleErr);
            s.addEventListener(Event.COMPLETE, onLoadComplete);
            s.addEventListener(ProgressEvent.PROGRESS, onProgress);

            var req:URLRequest = new URLRequest(url),
                context:SoundLoaderContext = new SoundLoaderContext(getBufferTime(), false);

            _url = url;
            setState(State.PREBUFFER);
            s.load(req, context);
        }

        override public function f_play(p:Number = 0):void {
            Utils.log('f_play');
            super.f_play(p);

            if (p === 0 && _pausePosition) {
                p = _pausePosition;
            }

            if (sc) {
                sc.removeEventListener(Event.SOUND_COMPLETE, onPlayComplete);
                sc.stop();
                sc = null;
            }

            if (_url) {
                sc = s.play(p, 0, stf);
                sc.addEventListener(Event.SOUND_COMPLETE, onPlayComplete);
                isPlaying = true;
            }
        }

        override public function f_pause():void {
            if (sc) {
                f_stop(sc.position);
            }
        }

        override public function f_stop(p:Number = -1):void {
            super.f_stop(p);
            // 判断sc是否存在是因为sc在play方法调用时才被延迟初始化
            if (sc) {
                sc.stop();
            }
            isPlaying = false;
        }
    }
}
