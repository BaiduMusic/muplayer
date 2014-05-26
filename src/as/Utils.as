package {
    import flash.events.*;
    import flash.external.ExternalInterface;

    public class Utils {
        public static function log(msg:String):void {
            ExternalInterface.call('console.log', 'flash:' + msg);
        }

        public static function callJS(fn:String, data:Object = undefined):void {
            ExternalInterface.call(fn, data);
        }
    }
}
