package {
    public interface IEngine {
        function getMute():Boolean;

        function setMute(m:Boolean):void;

        function getVolume():uint;

        function setVolume(v:uint):void;

        function load(url:String):void;

        function play(p:Number = 0):void;

        function pause():void;

        function stop(p:Number = 0):void;
    }
}
