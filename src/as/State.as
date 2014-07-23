package {
    // 标识歌曲播放状态的静态类
    public final class State {
        public static const NOT_INIT:int = -1;
        public static const CANPLAYTHROUGH:int = 0;
        public static const PREBUFFER:int = 1;
        public static const BUFFERING:int = 2;
        public static const PLAYING:int = 3;
        public static const PAUSE:int = 4;
        public static const STOP:int = 5;
        public static const END:int = 6;

        private static const STATES:Array = new Array(
            CANPLAYTHROUGH, PREBUFFER, BUFFERING, PLAYING,
            PAUSE, STOP, END
        );

        public static function validate(st:int):Boolean {
            return STATES.indexOf(st) != -1;
        }
    }
}
