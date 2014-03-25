package {
    import flash.display.Sprite;
    import flash.system.Security;
    import flash.errors.IOError;
    import flash.events.Event;
    import flash.events.IOErrorEvent;
    import flash.events.ProgressEvent;
    import flash.events.TimerEvent;
    import flash.external.ExternalInterface;
    import flash.media.Sound;
    import flash.media.SoundChannel;
    import flash.media.SoundTransform;
    import flash.net.URLRequest;
    import flash.utils.Timer;
    import flash.display.Stage;

    public class FlashPlayer extends Sprite {
        const S_NOOPEN:int = -1;
        const S_STOP:int = 0;
        const S_PLAYING:int = 1;
        const S_PAUSE:int = 2;
        const S_END:int = 3;
        const S_BUFFERING = 4;
        const S_READY = 5;

        const S1_NOINIT:int = -1;
        const S1_INIT:int = 0;
        const S1_LOADING:int = 1;
        const S1_LOADCOMPLETE:int = 2;
        const S1_PLAYCOMPLETE:int = 3;
        const S1_CLOSE:int = 4;
        const S1_ERROR:int = 5;

        const E_NOERROR:int = -1;
        const E_INIT:int = 0;
        const E_LOAD:int = 1;
        const E_PLAY:int = 2;
        const E_SECURITY:int = 3;
        const E_DEVICE:int = 4;

        const TIME_DELAY:int = 50;

        private var JS_INSTANCE:String = '';
        private var JS_ONLOAD:String = '._swfOnLoad';
        private var JS_ONPLAYSTATECHANGE:String = '._swfOnStateChange';
        private var JS_DATATIMER:String = '._datatimer';
        private var JS_STATUSTIMER:String = '._statustimer';
        private var JS_ERROR:String = '._error';

        // 播放状态
        //  -1: no open;
        //  0: stop;
        //  1: playing;
        //  2: pause;
        //  3: end (playComplete);
        //  4: buffering;
        //  5: ready (after load - pre-buffing);
        private var playStatus:int = S_NOOPEN;

        // 播放器状态
        //  -1: no init;
        //  0: init;
        //  1: loading;
        //  2: loadComplete;
        //  3: playComplete (end);
        //  4: close stream;
        //  5: error;
        private var playerStatus:int = S1_NOINIT;

        // 错误信息
        //  -1: no error
        //  0: init fail
        //  1: loading fail
        //  2: playing fail
        //  3: security fail
        //  4: device no support
        private var errorStatus:int = E_NOERROR;

        // 当前播放进度(ms)
        private var postion:int = 0;

        // 播放进度百分比[0-1]
        private var postionPct:Number = 0;

        // 音频总长度(ms)
        private var length:int = 0;

        // 音量(0-100)
        private var volume:int = 50;

        // 恢复静音记录的音量
        private var volume_tmp:int = 50;

        // 静音状态
        private var mute:Boolean = false;

        // 载入进度百分比(0-1)
        private var loadedPct:Number = 0;

        // 外部文件总字节
        private var totalByte:int = 0;

        // 已载入字节
        private var loadedByte:int = 0;

        // 最小缓冲时间(ms)
        // MP3 数据保留在 Sound 对象的缓冲区中的最小毫秒数。
        // 在开始回放以及在网络中断后继续回放之前，Sound 对
        // 象将一直等待直至至少拥有这一数量的数据为止。
        // 默认值为1000(1秒)
        private var bufferTime:Number = 6000;

        // 播放循环次数
        // 0: 不循环
        private var loop:int = 0;

        // 外部文件地址
        private var url:String = '';

        private var player:Sound;
        private var playerChannel:SoundChannel;
        private var playerSTF:SoundTransform;

        // 用于在flash中显示播放中各种状态
        private var playerTimer:Timer;

        // 用于实时监控播放时的postion
        private var statusTimer:Timer;

        // 用于实时监控播放时的loadedByte / totalByte
        private var dataTimer:Timer;

        // 调用js接口的定时器开启状态
        // 默认关闭
        private var timerOpened:Boolean = false;

        public function getPlayStatus():int {
            return playStatus;
        }

        public function getPlayerStatus():int {
            return playerStatus;
        }

        public function getErrorStatus():int {
            return errorStatus;
        }

        public function getPostion():int {
            return (playStatus == S_STOP || playStatus == S_NOOPEN) ? 0 :
                playerChannel ? playStatus == S_PAUSE ? postion :
                playerChannel.position : 0;
        }

        public function getPostionPct():Number {
            return postionPct;
        }

        public function getLength():int {
            return length;
        }

        public function getVolume():int {
            return mute ? volume_tmp : volume;
        }

        public function getMute():Boolean {
            return mute;
        }

        public function getLoadedPct():Number {
            return loadedPct;
        }

        public function getTotalByte():int {
            return totalByte;
        }

        public function getLoadedByte():int {
            return loadedByte;
        }

        public function getBufferTime():Number {
            return bufferTime;
        }

        public function setBufferTime(bt:Number):void {
            bufferTime = bt;
        }

        public function getLoop():int {
            return loop;
        }

        public function setLoop(lp:int):void {
            loop = lp;
        }

        public function getUrl():String {
            return url;
        }

        public function FlashPlayer() {
            this.addEventListener(Event.ENTER_FRAME, checkStage);
        }

        private var autoplay:int = -1;

        public function loadFromFlashVars():void {
            JS_INSTANCE = stage.loaderInfo.parameters['_instanceName'];
            var _buffertime = stage.loaderInfo.parameters['_buffertime'] || bufferTime;
            setBufferTime(_buffertime);
        }

        public function getData(key:String) {
            switch (key) {
                case 'url':
                    return getUrl();
                    break;
                case 'playStatus':
                    return getPlayStatus();
                    break;
                case 'playerStatus':
                    return getPlayerStatus();
                    break;
                case 'errorStatus':
                    return getErrorStatus();
                    break;
                case 'currentPosition':
                    return getPostion();
                    break;
                case 'length':
                    return getLength();
                    break;
                case 'volume':
                    return getVolume();
                    break;
                case 'mute':
                    return getMute();
                    break;
                case 'loadedPct':
                    return getLoadedPct();
                    break;
                case 'postionPct':
                    return getPostionPct();
                    break;
                case 'totalByte':
                    return getTotalByte();
                    break;
                case 'loadedByte':
                    return getLoadedByte();
                    break;
                case 'loaderBuffer':
                    return getBufferTime();
                    break;
                case 'loop':
                    return getLoop();
                    break;
                default:
                    return;
            }
        }

        public function setData(key:String, value) {
            switch (key) {
                case 'url':
                    return f_load(value);
                    break;
                case 'volume':
                    return setVolume(value);
                    break;
                case 'currentPosition':
                    return f_play(value);
                    break;
                case 'mute':
                    return setMute(value);
                    break;
                case 'loaderBuffer':
                    return setBufferTime(value);
                    break;
            }
        }

        public function init():void {
            playerSTF = new SoundTransform(volume / 100, 0);
        }

        public function reset():void {
            url = '';
            player = null;
            player = new Sound();
            playStatus = S_NOOPEN;
            playerStatus = S1_INIT;
            errorStatus = E_NOERROR;
            resetData();
        }

        public function resetData() {
            length = 0;
            loadedPct = 0;
            postion = 0;
            postionPct = 0;
            totalByte = 0;
            loadedByte = 0;
        }

        public function f_load(u:String):void {
            f_stop(false);
            reset();
            var urlRequest:URLRequest = new URLRequest(u);
            try {
                player.load(urlRequest);
                player.addEventListener(Event.COMPLETE, completeListener);
                player.addEventListener(IOErrorEvent.IO_ERROR, ioErrorListener);
                player.addEventListener(ProgressEvent.PROGRESS, progressListener);
                playStatus = S_READY;
                callJsFunction(JS_ONPLAYSTATECHANGE, playStatus);
            } catch(error:IOError) {
                errorStatus = E_LOAD;
            } catch(error:SecurityError) {
                errorStatus = E_SECURITY;
            } catch(error:Error) {
                errorStatus = E_LOAD;
            } finally {
                url = u;
            }
        }

        public function f_play(p:Number = -1):void {
            if (playStatus == S_STOP) {
                if (url) {
                    f_load(url);
                }
            }

            var l:int = getLoop();
            stopChannel(playerChannel);

            if (p < 0 && p != -1) {
                p = 0;
            }
            if (p > length) {
                p = length;
            }

            try {
                if (p == -1) {
                    playerChannel = player.play(postion, l, playerSTF);
                } else {
                    playerChannel = player.play(p, l, playerSTF);
                }
                playerChannel.addEventListener('soundComplete', soundCompleteListener);
                startSetStatus();
                setVolume(getVolume());

                errorStatus = E_NOERROR;
                if (playStatus != S_PLAYING && playerStatus != S_BUFFERING) {
                    if (!(player.isBuffering && playStatus == S_READY)) {
                        playStatus = S_PLAYING;
                        callJsFunction(JS_ONPLAYSTATECHANGE, playStatus);
                    }
                }
            } catch(e:Error) {
                errorStatus = E_PLAY;
                playerStatus = S1_ERROR;
            }
        }

        private function initExternalInterface():void {
            try {
                Security.allowDomain('*');
                loadFromFlashVars();
                if (ExternalInterface.available) {
                    ExternalInterface.addCallback('f_load', f_load);
                    ExternalInterface.addCallback('f_play', f_play);
                    ExternalInterface.addCallback('f_stop', f_stop);
                    ExternalInterface.addCallback('f_pause', f_pause);
                    ExternalInterface.addCallback('setVolume', setVolume);
                    ExternalInterface.addCallback('closeStream', closeStream);
                    ExternalInterface.addCallback('getData', getData);
                    ExternalInterface.addCallback('setData', setData);
                    callJsFunction(JS_ONLOAD, undefined);
                }
                init();
            } catch(error:Error) { }
        }

        private function checkStage(e:Event = null):void {
            if (stage.stageWidth > 0) {
                this.removeEventListener(Event.ENTER_FRAME, checkStage);
                initExternalInterface();
            }
        }

        private function stopChannel(chl:SoundChannel):void {
            if (chl != null) {
                try {
                    chl.stop();
                } catch(error:Error) {
                    errorStatus = E_PLAY;
                } finally {
                    chl = null;
                }
            }
        }

        public function f_stop(b:Boolean = true):void{
            if (playStatus == S_STOP) {
                return;
            }
            try {
                stopChannel(playerChannel);
                playerChannel = null;
                closeStream();
            } catch(error:Error) {
                errorStatus = E_PLAY;
            } finally {
                playStatus = S_STOP;
                if (b) {
                    callJsFunction(JS_ONPLAYSTATECHANGE, playStatus);
                }
                postion = 0;
                stopSetStatus();
            }
        }

        public function f_pause():void {
            if (playStatus == S_PAUSE || playStatus == S_STOP || playStatus == S_END) {
                return;
            }
            if (playerChannel != null) {
                try {
                    postion = (playStatus == S_STOP || playStatus == S_NOOPEN) ? 0 :
                        playerChannel.position;
                    playerChannel.stop();
                } catch(error:Error) {
                    errorStatus = E_PLAY;
                } finally {
                    playStatus = S_PAUSE;
                    callJsFunction(JS_ONPLAYSTATECHANGE, playStatus);
                    stopSetStatus();
                }
            }
        }

        public function closeStream():void {
            if (player != null) {
                try {
                    player.close();
                } catch (e:IOError) { } finally {
                    player.removeEventListener(Event.COMPLETE, completeListener);
                    player.removeEventListener(IOErrorEvent.IO_ERROR, ioErrorListener);
                    player.removeEventListener(ProgressEvent.PROGRESS, progressListener);
                    player = null;
                }
            }
        }

        public function setVolume(v:int):void {
            if (mute) {
                volume_tmp = v;
                volume = 0;
            } else {
                volume = v > 100 ? 100 : v < 0 ? 0 : v;
            }
            playerSTF.volume = volume / 100;
            if (playerChannel) {
                playerChannel.soundTransform = playerSTF;
            }
        }

        public function setMute(m:Boolean = false):void {
            if (m == mute) {
                return;
            }
            if (m) {
                volume_tmp = getVolume();
                setVolume(0);
                mute = true;
            } else {
                mute = false;
                setVolume(volume_tmp);
            }
        }

        public function startDataTimer():void {
            if (timerOpened && dataTimer == null) {
                dataTimer = new Timer(TIME_DELAY, 0);
                dataTimer.addEventListener('timer', sendDataListener);
                dataTimer.start();
            }
        }

        public function stopDataTimer():void {
            if (dataTimer != null) {
                dataTimer.stop();
                dataTimer = null;
            }
        }

        public function sendDataListener(e:TimerEvent):void {
            var data:Object = {
                    complete: false,
                    length: getLength(),
                    totalByte: getTotalByte(),
                    loadedByte: getLoadedByte(),
                    loadedPct: getLoadedPct()
                };

            callJsFunction(JS_DATATIMER, data);
        }

        public function startSetStatus() :void{
            if (statusTimer == null) {
                statusTimer = new Timer(TIME_DELAY,0);
                statusTimer.addEventListener('timer', setStatusListener);
                statusTimer.start();
            }
        }

        public function stopSetStatus():void {
            if (statusTimer != null) {
                statusTimer.stop();
                statusTimer = null;
            }
        }

        public function completeListener(e:Event):void {
            playerStatus = S1_LOADCOMPLETE;
            errorStatus = E_NOERROR;
            if (player != null) {
                length = player.length;
                totalByte = loadedByte = player.bytesTotal;
                loadedPct = 1;
            }
            if (timerOpened) {
                var data:Object = {
                    complete:true,
                    length:getLength(),
                    totalByte:getTotalByte(),
                    loadedByte:getTotalByte(),
                    loadedPct:1
                };
                callJsFunction(JS_DATATIMER, data);
            }
        }

        public function ioErrorListener(e:IOErrorEvent):void {
            playerStatus = S1_ERROR;
            errorStatus = E_LOAD;
            resetData();
            callJsFunction(JS_ERROR, e.type);
        }

        public function progressListener(e:ProgressEvent):void {
            playerStatus = S1_LOADING;
            errorStatus = E_NOERROR;
            if (player != null) {
                totalByte = player.bytesTotal;
                loadedByte = player.bytesLoaded;
                length = player.length * totalByte / loadedByte;
                loadedPct = (Math.floor(loadedByte * 100 / totalByte)) / 100;
            }
        }

        public function soundCompleteListener(e:Event):void {
            stopSetStatus();
            playerStatus = S1_PLAYCOMPLETE;
            playStatus = S_END,
            postionPct = 1,
            postion = getLength(),

            callJsFunction(JS_ONPLAYSTATECHANGE, playStatus);

            if (timerOpened) {
                stopSetStatus();
                var data:Object = {
                    soundComplete:true,
                    postion:getLength(),
                    postionPct:1,
                    playStatus:getPlayStatus(),
                    vol:getVolume()
                };
                callJsFunction(JS_STATUSTIMER, data);
            }
        }

        public function setStatusListener(e:TimerEvent):void {
            if (playerChannel != null) {
                postionPct = (Math.floor(postion * 100 / length)) / 100;
                var tmpPlayState = playStatus;
                playStatus = player.isBuffering ?
                    (playStatus == S_READY ? S_READY : S_BUFFERING) : S_PLAYING;
                if (tmpPlayState != playStatus) {
                    callJsFunction(JS_ONPLAYSTATECHANGE, playStatus);
                }
            }
            if (timerOpened) {
                var data:Object = {
                    soundComplete: false,
                    postion: getPostion(),
                    postionPct: getPostionPct(),
                    playStatus: getPlayStatus(),
                    vol: getVolume()
                };
                callJsFunction(JS_STATUSTIMER, data);
            }
        }

        public function callJsFunction(callName:String, data) {
            var reg:RegExp = /[()=]/ig;
            if (!reg.test(JS_INSTANCE)) {
                if(ExternalInterface.available)
                    ExternalInterface.call(JS_INSTANCE + callName, data);
            }
        }

        private function log(msg) {
            ExternalInterface.call('console.log', 'fmp: ' + msg);
        }
    }
}
