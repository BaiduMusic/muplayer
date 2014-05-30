package {
    import flash.events.*;
    import flash.external.ExternalInterface;
    import flash.media.SoundTransform;
    import flash.net.NetConnection;
    import flash.net.NetStream;
    import flash.net.URLRequest;
    import flash.utils.Timer;

    public class MP4Core extends BaseCore {
        private var nc:NetConnection;
        private var ns:NetStream;

        override public function init():void {
            super.init();
            if (ExternalInterface.available) {
                reset();

                nc = new NetConnection();
                nc.addEventListener(NetStatusEvent.NET_STATUS, onNetStatus);
                nc.connect(null);
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

        // 事件含义可参考: http://help.adobe.com/zh_CN/AS2LCR/Flash_10.0/help.html?content=00001409.html
        private function onNetStatus(e:NetStatusEvent):void {
            // 实测发现，Play.Start会先于Buffer.Full触发，因此这段事件可以认为是在onProgress做一些buffering
            switch (e.info.code) {
                case 'NetStream.Play.Start':
                    setState(State.BUFFERING);
                    break;
                case 'NetStream.Buffer.Full':
                    setState(State.PLAYING);
                case 'NetStream.Play.Stop':
                    break;
                case 'NetStream.Seek.InvalidTime':
                    onPlayComplete();
                    break;
                case 'NetStream.Play.StreamNotFound':
                    handleErr();
                    break;
            }
        }

        private function onMetaData(meta:Object):void {
            if (meta.duration) {
                _length = meta.duration;
            }
        }

        private function onProgress():void {
            if (!_bytesTotal) {
                _bytesTotal = ns.bytesTotal;
            }
            _bytesLoaded = ns.bytesLoaded;
            _loadedPct = Math.round(100 * _bytesLoaded / _bytesTotal) / 100;

            if (!_length) {
                // 估算的音频时长，精确值在onMetaData中获得
                _length = Math.ceil(ns.time / _bytesLoaded * _bytesTotal);
            }
        }

        override protected function onPlayTimer(e:TimerEvent = null):void {
            if (_state == State.BUFFERING) {
                onProgress();
            }

            _position = ns.time;
            if (_position > _length) {
                _length = _position;
            }
            _positionPct = Math.round(100 * _position / _length) / 100;
        }

        override public function setVolume(v:uint):Boolean {
            var success:Boolean = super.setVolume(v);
            if (success && ns) {
                ns.soundTransform = stf;
            }
            return success;
        }

        override public function reset():void {
            if (ns) {
                ns.removeEventListener(NetStatusEvent.NET_STATUS, onNetStatus);
                ns = null;
            }
        }

        override public function load(url:String):void {
            stop();

            try {
                ns && ns.close();
            } catch (err:Error) {
            } finally {
                reset();
            }

            var customClient:Object = new Object();
            customClient.onMetaData = onMetaData;

            ns = new NetStream(nc);
            ns.addEventListener(NetStatusEvent.NET_STATUS, onNetStatus);
            ns.client = customClient;

            _url = url;
            setState(State.PREBUFFER);
        }

        override public function play(p:Number = 0):void {
            if (_state != State.PLAYING) {
                if (p == 0 && _pausePosition) {
                    p = _pausePosition;
                }
                try {
                    if (_state == State.PAUSE) {
                        ns.seek(p);
                        ns.resume();
                    } else {
                        ns.play(_url);
                    }
                } catch (err:Error) {
                    return handleErr(err);
                }
                playerTimer = new Timer(Consts.TIMER_INTERVAL);
                playerTimer.addEventListener(TimerEvent.TIMER, onPlayTimer);
                playerTimer.start();
            }
        }

        override public function pause():void {
            stop(ns.time);
        }

        override public function stop(p:Number = 0):void {
            super.stop(p);
            // 判断ns是否存在是因为ns在load方法调用时才被延迟初始化
            if (ns) {
                ns.pause();
            }
        }
    }
}
