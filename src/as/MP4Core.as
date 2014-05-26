package {
    import flash.events.*;
    import flash.errors.IOError;
    import flash.external.ExternalInterface;

    import BaseCore;
    import Consts;
    import State;

    public class MP4Core extends BaseCore {
        override public function init():void {
            super.init();
            if (ExternalInterface.available) {
                reset();
                ExternalInterface.addCallback('load', load);
                ExternalInterface.addCallback('play', play);
                ExternalInterface.addCallback('pause', pause);
                ExternalInterface.addCallback('stop', stop);
                ExternalInterface.addCallback('getData', getData);
                ExternalInterface.addCallback('setData', setData);
                callJS(Consts.SWF_ON_LOAD);
            }
        }
    }
}
