package {
    import flash.display.Sprite;
    import flash.events.*;
    import flash.errors.IOError;
    import flash.external.ExternalInterface;
    import flash.media.SoundTransform;

    import Utils;
    import State;

    public class MP4Core extends Sprite {
        private const TIMER_INTERVAL:int = 200;

        public function MP3Core() {
            Utils.checkStage(this, 'init');
        }

        public function init():void {
            Security.allowDomain('*');
            Security.allowInsecureDomain('*');
            loadFlashVars(loaderInfo.parameters);
            if (ExternalInterface.available) {
                reset();
                stf = new SoundTransform(volume / 100, 0);
                ExternalInterface.addCallback('load', load);
                ExternalInterface.addCallback('play', play);
                ExternalInterface.addCallback('pause', pause);
                ExternalInterface.addCallback('stop', stop);
                ExternalInterface.addCallback('getData', getData);
                ExternalInterface.addCallback('setData', setData);
                callJS(SWF_ON_LOAD);
            }
        }

        public function pause():void {}
    }
}
