package {
    import flash.events.*;
    import flash.external.ExternalInterface;
    import flash.media.Sound;
    import flash.media.SoundChannel;
    import flash.media.SoundTransform;
    import flash.media.SoundLoaderContext;
    import flash.net.URLRequest;

    public class MP3Core extends BaseCore {
        private var s:Sound;
        private var sc:SoundChannel;

        override public function init():void {
            super.init();
            if (ExternalInterface.available) {
                reset();
                ExternalInterface.addCallback('f_load', f_load);
                ExternalInterface.addCallback('f_play', f_play);
                ExternalInterface.addCallback('f_pause', f_pause);
                ExternalInterface.addCallback('f_stop', f_stop);
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
            _loadedPct = Math.round(100 * _bytesLoaded / _bytesTotal) / 100;

            if (!_length) {
                // 估算的音频时长，精确值需要在onLoadComplete中获得。
                _length = Math.ceil(s.length / _bytesLoaded * _bytesTotal);
            }
        }

        override protected function onPlayTimer(e:TimerEvent = null):void {
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
                context:SoundLoaderContext = new SoundLoaderContext(getBufferTime());

            _url = url;
            setState(State.PREBUFFER);
            s.load(req, context);
        }

        override public function f_play(p:Number = 0):void {
            super.f_play(p);

            if (p == 0 && _pausePosition) {
                p = _pausePosition;
            }

            if (sc) {
                sc.removeEventListener(Event.SOUND_COMPLETE, onPlayComplete);
                sc.stop();
                sc = null;
            }

            sc = s.play(p, 0, stf);
            sc.addEventListener(Event.SOUND_COMPLETE, onPlayComplete);
        }

        override public function f_pause():void {
            if (sc) {
                f_stop(sc.position);
            }
        }

        override public function f_stop(p:Number = 0):void {
            super.f_stop(p);
            // 判断sc是否存在是因为sc在play方法调用时才被延迟初始化
            if (sc) {
                sc.stop();
            }
        }
    }
}
