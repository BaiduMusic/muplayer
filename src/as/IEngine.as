package {
    public interface IEngine {
        function getState():int;

        function setState(st:int):void;

        function getMute():Boolean;

        function setMute(m:Boolean):void;

        function getVolume():uint;

        function setVolume(v:uint):Boolean;

        function getUrl():String;

        function getLength():uint;

        function getPosition():uint;

        function getBufferTime():uint;

        function getLoadedPct():Number;

        function getPositionPct():Number;

        function getBytesTotal():uint;

        function getBytesLoaded():uint;

        // 以f_前缀开头，是因为这些方法要通过ExternalInterface暴露给JS调用
        // 在IE 8下会引起这个issue: https://github.com/Baidu-Music-FE/muplayer/issues/15
        function f_load(url:String):void;

        function f_play(p:Number = 0):void;

        function f_pause():void;

        function f_stop(p:Number = -1):void;
    }
}
