do (root = @, factory = ->
    root = @

    return $.extend({
        namespace: root._mu
        version: '0.9.2'

        # XXX: timerResolution = 25ms是最小的计时粒度,
        # 这个不经测试调优就尽量不要改, 会影响部分统计数据和性能。
        timerResolution: 25

        cdn: 'http://apps.bdimg.com/libs/muplayer/'

        engine:
            TYPES:
                FLASH_MP3: 'FlashMP3Core'
                FLASH_MP4: 'FlashMP4Core'
                AUDIO: 'AudioCore'

            EVENTS:
                STATECHANGE: 'engine:statechange'           # 播放状态改变事件（STATES）
                POSITIONCHANGE: 'engine:postionchange'      # 播放时播放进度改变事件
                PROGRESS: 'engine:progress'                 # 加载时加载进度改变事件
                ERROR: 'engine:error'                       # 播放过程中出错时的事件
                INIT: 'engine:init'                         # 播放器初始化成功时的事件
                INIT_FAIL: 'engine:init_fail'               # 播放器初始化失败时的事件
                WAITING_TIMEOUT: 'engine:waiting_timeout'   # 播放器发生卡断超时时的事件

            # 状态影响EVENTS.STATECHANGE派发的事件，原则上派发的事件应保持和HTML5 Audio规范一致。
            # HTML5 Audio相关事件可参考: http://www.whatwg.org/specs/web-apps/current-work/multipage/the-video-element.html#mediaevents
            STATES:
                CANPLAYTHROUGH: 'canplaythrough'
                PREBUFFER: 'waiting'
                BUFFERING: 'loadeddata'
                PLAYING: 'playing'
                PAUSE: 'pause'
                STOP: 'suspend'
                END: 'ended'

            # 内核错误码, 参考HTML5 Audio错误状态:
            # http://dev.w3.org/html5/spec-author-view/video.html#error-codes
            ERRCODE:
                MEDIA_ERR_ABORTED: '1'
                MEDIA_ERR_NETWORK: '2'
                MEDIA_ERR_DECODE: '3'
                MEDIA_ERR_SRC_NOT_SUPPORTED: '4'
    }, if typeof root._mu is 'undefined' then {} else root._mu.cfg)
) ->
    # _mu是muplayer约定的namespace,
    # 放到这个前置配置中初始化比较合适。
    if typeof root._mu is 'undefined'
        root._mu = {}

    if typeof exports is 'object'
        module.exports = factory()
    else if typeof define is 'function' and define.amd
        define(factory)
    else
        root._mu.cfg = factory()
