package {
    // 标识歌曲播放状态的静态类
    public final class State {
        public static const CANPLAYTHROUGH:int = 1;
        public static const PREBUFFER:int = 2;
        public static const BUFFERING:int = 3;
        public static const PLAYING:int = 4;
        public static const PAUSE:int = 5;
        public static const STOP:int = 6;
        public static const END:int = 7;

        private static const STATES:Array = new Array(
            CANPLAYTHROUGH, PREBUFFER, BUFFERING, PLAYING,
            PAUSE, STOP, END
        );

        public static function validate(st:int):Boolean {
            return STATES.indexOf(st) != -1;
        }
    }
}
