do (root = @, factory = (cfg, utils, Timer, EngineCore) ->
    {EVENTS, STATES, ERRCODE} = cfg.engine
    timerResolution = cfg.timerResolution

    # fmp.swf中约定的状态返回码。
    STATESCODE =
        '-1': STATES.NOT_INIT
        '1': STATES.CANPLAYTHROUGH
        '2': STATES.PREBUFFER
        '3': STATES.BUFFERING
        '4': STATES.PLAYING
        '5': STATES.PAUSE
        '6': STATES.STOP
        '7': STATES.END

    class FlashCore extends EngineCore
        @defaults:
            expressInstaller: 'expressInstall.swf'

        constructor: (options) ->
            @opts = opts = $.extend({}, FlashCore.defaults, @defaults, options)

            @_state = STATES.NOT_INIT
            @_loaded = false
            @_queue = []

            @_needFlashReady([
                'play', 'pause', 'stop', 'setCurrentPosition',
                '_setUrl', '_setVolume', '_setMute'
            ])
            @_unexceptionGet([
                'getCurrentPosition', 'getLoadedPercent', 'getTotalTime'
            ])

            baseDir = opts.baseDir

            # setTimeout的方式生成自增id。
            id = 'muplayer_' + setTimeout((->), 0)
            instanceName = opts.instanceName + '_' + id

            utils.namespace('engines')[instanceName] = @
            # TODO: 有没有不hard code的方式呢?
            instanceName = '_mu.engines.' + instanceName

            @flash = $.flash.create
                swf: baseDir + opts.swf
                id: id
                height: 1
                width: 1
                allowscriptaccess: 'always'
                wmode : 'transparent'
                expressInstaller: baseDir + opts.expressInstaller
                flashvars:
                    _instanceName: instanceName
                    _buffertime: 5000
            opts.$el.append(@flash)
            @_initEvents()

        _test: () ->
            opts = @opts
            if not @flash or not $.flash.hasVersion(opts.flashVer)
                return false
            true

        # TODO: 暂时通过轮询的方式派发加载、播放进度事件。
        # 这里需要注意性能, 看能否直接监听对应的flash事件。
        _initEvents: () ->
            # progressTimer记录加载进度。
            @progressTimer = new Timer(timerResolution)
            # positionTimer记录播放进度。
            @positionTimer = new Timer(timerResolution)

            triggerProgress = () =>
                per = @getLoadedPercent()
                if @_lastPer isnt per
                    @_lastPer = per
                    @trigger(EVENTS.PROGRESS, per)
                @progressTimer.stop() if per is 1
            triggerPosition = () =>
                pos = @getCurrentPosition()
                if @_lastPos isnt pos
                    @_lastPos = pos
                    @trigger(EVENTS.POSITIONCHANGE, pos)

            @progressTimer.every('100 ms', triggerProgress)
            @positionTimer.every('100 ms', triggerPosition)

            @on EVENTS.STATECHANGE, (e) =>
                st = e.newState

                # 将progressTimer和positionTimer的状态机制分离在两个
                # switch中会更灵活, 即便逻辑基本一致也不要混在一起,
                # 后续好扩展。
                switch st
                    when STATES.PREBUFFER, STATES.PLAYING
                        @progressTimer.start()
                    when STATES.PAUSE, STATES.STOP
                        @progressTimer.stop()
                    when STATES.END
                        @progressTimer.reset()

                switch st
                    when STATES.PLAYING
                        @positionTimer.start()
                    when STATES.PAUSE, STATES.STOP
                        @positionTimer.stop()
                        # 防止轮询延迟, 暂停时主动trigger, 保证进度准确。
                        triggerPosition()
                    when STATES.END
                        @positionTimer.reset()

        # 需要依赖flash加载后执行的方法包装器。
        # 更优雅的方式应该是用类似Java的annotation语法。
        # 可以考虑用: https://developers.google.com/closure/compiler/docs/js-for-compiler
        _needFlashReady: (fnames) ->
            for name in fnames
                @[name] = utils.wrap @[name], (fn, args...) =>
                    if @_loaded
                        fn.apply(@, args)
                    else
                        @_pushQueue(fn, args)
                    @

        _unexceptionGet: (fnames) ->
            for name in fnames
                @[name] = utils.wrap @[name], (fn, args...) =>
                    try
                        fn.apply(@, args)
                    catch
                        0

        _pushQueue: (fn, args) ->
            @_queue.push([fn, args])

        _fireQueue: () ->
            while @_queue.length
                [fn, args] = @_queue.shift()
                fn.apply(@, args)

        play: () ->
            @flash.f_play()
            @

        pause: () ->
            @flash.f_pause()
            @

        stop: () ->
            @flash.f_stop()
            @

        _setUrl: (url) ->
            @flash.f_load(url)

        setUrl: (url) ->
            if url
                @_setUrl(url)
                # 检测后缀与实际资源不符的情况。
                # 错误统一抛EVENTS.ERROR事件, 由调用方决定如何处理。
                do () =>
                    checker = null
                    check = (e) =>
                        if e.newState is STATES.PLAYING and e.oldState is STATES.PREBUFFER
                            checker = setTimeout(() =>
                                @off(EVENTS.STATECHANGE, check)
                                if @getCurrentPosition() < 100
                                    @setState(STATES.END)
                                    @trigger(EVENTS.ERROR, ERRCODE.MEDIA_ERR_SRC_NOT_SUPPORTED)
                            , 2000)
                        else
                            clearTimeout(checker)
                    @off(EVENTS.STATECHANGE, check).on(EVENTS.STATECHANGE, check)
            super(url)

        getState: (code) ->
            STATESCODE[code] or @_state

        _setVolume: (volume) ->
            @flash.setData('volume', volume)

        setVolume: (volume) ->
            @_setVolume(volume)
            super(volume)

        _setMute: (mute) ->
            @flash.setData('mute', mute)

        setMute: (mute) ->
            @_setMute(mute)
            super(mute)

        setCurrentPosition: (ms) ->
            @flash.f_play(ms)
            @

        getCurrentPosition: () ->
            @flash.getData('position')

        getLoadedPercent: () ->
            @flash.getData('loadedPct')

        getTotalTime: () ->
            @flash.getData('length')

        # _swf前缀的都是AS的回调方法。
        _swfOnLoad: () ->
            @_loaded = true
            # 加延时为0的setTimeout是为了防止_fireQueue时阻塞页面动画等效果。
            setTimeout(() =>
                @_fireQueue()
            , 0)

        _swfOnStateChange: (code) ->
            @setState(@getState(code))

        _swfOnErr: (e) ->
            @setState(STATES.END)
            @trigger(EVENTS.ERROR)
            console?.error(e)

    FlashCore
) ->
    if typeof exports is 'object'
        module.exports = factory()
    else if typeof define is 'function' and define.amd
        define([
            'muplayer/core/cfg'
            'muplayer/core/utils'
            'muplayer/lib/Timer'
            'muplayer/core/engines/engineCore'
            'muplayer/lib/jquery.swfobject'
        ], factory)
    else
        root._mu.FlashCore = factory(
            _mu.cfg
            _mu.utils
            _mu.Timer
            _mu.EngineCore
        )
