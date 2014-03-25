do (root = this, factory = () ->
    root = this

    return $.extend({
        namespace: root._mu
        debug: false
        version: '1.0.0'

        # XXX: timerResolution = 25ms是最小的计时粒度,
        # 这个不经测试调优就尽量不要改, 会影响部分统计数据和性能。
        timerResolution: 25

        emptyMP3: '/mp3/empty.mp3'
        expressInstaller: '/swf/expressInstall.swf'
        engine:
            TYPES:
                FLASH: 'FlashCore'
                AUDIO: 'AudioCore'
            EVENTS:
                STATECHANGE: 'engine:statechange'       # 播放状态改变事件(STATES)
                POSITIONCHANGE: 'engine:postionchange'  # 播放时播放进度改变事件
                PROGRESS: 'engine:progress'             # 加载时加载进度改变事件
                ERROR: 'engine:error'                   # 播放过程中出错时的事件
                INIT: 'engine:init'                     # 播放器初始化成功时的事件
                INITFAIL: 'engine:initfail'             # 播放器初始化失败时的事件
            STATES:
                INIT: 'init'                            # 等待初始化完成
                READY: 'ready'                          # 初始化成功(DOM已加载)
                STOP: 'stop'
                PLAY: 'play'
                PAUSE: 'pause'
                END: 'end'
                BUFFERING: 'buffering'
                PREBUFFER: 'pre-buffer'
                ERROR: 'error'
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
