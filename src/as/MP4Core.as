package {
    import flash.events.*;
    import flash.external.ExternalInterface;
    import flash.media.SoundTransform;
    import flash.net.NetConnection;
    import flash.net.NetStream;

    import BaseCore;
    import Consts;
    import State;
    import Utils;

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

        private function onNetStatus(e:NetStatusEvent):void {
            Utils.log(e.info.code);
            switch (e.info.code) {
                case 'NetConnection.Connect.Success':
                    break;
                case 'NetStream.Play.Start':
                    break;
                case 'NetStream.Play.Stop':
                    break;
                case 'NetStream.Seek.InvalidTime':
                    break;
                case 'NetStream.Play.StreamNotFound':
                    break;
            }
        }

        private function onMetaData(info:Object):void {
            Utils.log(info);
        }

        override protected function onPlayComplete(e:Event = null):void {
        }

        override protected function onPlayTimer(e:TimerEvent = null):void {
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
            Utils.log('load: ' + url);
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
            super.play(p);
            if (_state != State.PLAYING) {
                try {
                    ns.play(_url, p);
                } catch (err:Error) {
                    handleErr(err);
                }
            }
        }

        override public function pause():void {
            stop(ns.time);
        }

        override public function stop(p:Number = 0):void {
            super.stop();
            // 判断ns是否存在是因为ns在load方法调用时才被延迟初始化
            if (ns) {
                ns.pause();
            }
        }
    }
}
