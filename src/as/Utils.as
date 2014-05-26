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

        public static function checkStage(obj:Object, callback:String):void {
            function check(e:Event = null):void {
                if (obj.stage.stageWidth > 0) {
                    obj.removeEventListener(Event.ENTER_FRAME, check);
                    obj[callback]();
                }
            }

            obj.addEventListener(Event.ENTER_FRAME, check);
        }
    }
}
