do (root = this, factory = (cfg, utils, EngineCore, Modernizr) ->
    {TYPES, EVENTS, STATES, ERRCODE} = cfg.engine

    win = window
    emptyMP3 = cfg.emptyMP3

    class AudioCore extends EngineCore
        @defaults:
            # Audio是否可以播放的置信度, 可选值是maybe, probably或空字符。
            # 参考: http://www.whatwg.org/specs/web-apps/current-work/multipage/the-video-element.html#dom-navigator-canplaytype
            confidence: 'maybe'
            preload: false
            autoplay: false
        _supportedTypes: []
        engineType: TYPES.AUDIO

        constructor: (options) ->
            @opts = opts = $.extend(AudioCore.defaults, options)
            levels =
                '': 0
                maybe: 1
                probably: 2
            least = levels[opts.confidence]

            audio = Modernizr.audio
            return @ unless audio
            @_supportedTypes.push(k) for k, v of audio when levels[v] >= least

            # 对于绝大多数浏览器而言, audio标签和Audio对象的方式是等价的。
            # 参考: http://www.jplayer.org/HTML5.Audio.Support/
            audio = new Audio()
            audio.preload = opts.preload
            audio.autoplay = opts.autoplay
            # event listener封装, 支持链式调用。
            audio.on = (type, listener) =>
                audio.addEventListener(type, listener, false)
                audio
            audio.off = (type, listener) =>
                audio.removeEventListener(type, listener, false)
                audio
            @audio = audio

            @_needCanPlay([
                'play', 'setCurrentPosition'
            ])
            @_initEvents()

            # 用于HACK Audio在IOS上的限制, 参考: http://www.ibm.com/developerworks/library/wa-ioshtml5/
            playEmpty = () =>
                @setUrl(emptyMP3).play()
                win.removeEventListener('touchstart', playEmpty, false)
            win.addEventListener('touchstart', playEmpty, false)

        _test: (trigger) ->
            return false if Modernizr.audio is false or @_supportedTypes.length is 0
            trigger and @trigger(EVENTS.INITFAIL, @engineType)
            true

        # 事件类型参考: http://www.w3schools.com/tags/ref_eventattributes.asp
        _initEvents: () ->
            trigger = @trigger
            @trigger = (type, listener) =>
                trigger.call(@, type, listener) if @getUrl() isnt emptyMP3

            @audio.on('loadstart', () =>
                @setState(STATES.PREBUFFER)
            ).on('playing', () =>
                @setState(STATES.PLAY)
            ).on('pause', () =>
                @setState(@getCurrentPosition() and STATES.PAUSE or STATES.STOP)
            ).on('ended', () =>
                @setState(STATES.END)
            ).on('error', () =>
                @setState(STATES.ERR)
                @trigger(EVENTS.ERROR, ERRCODE.MEDIA_ERR_NETWORK)
            ).on('waiting', () =>
                @setState(@getCurrentPosition() and STATES.BUFFERING or STATES.PREBUFFER)
            ).on('timeupdate', () =>
                @trigger(EVENTS.POSITIONCHANGE, @getCurrentPosition())
            ).on('progress', () =>
                # TODO: 还需要progress事件, 暂时因为IOS及Chrome下会因歌曲缓存导致progress不被触发而未被添加。
                # 后续应参考audiojs的方式解决:
                # https://github.com/kolber/audiojs/blob/44b1359a9f486c93ff5bd15e225449bc436ff6b0/audiojs/audio.js#L501
            )

        _needCanPlay: (fnames) ->
            audio = @audio
            for name in fnames
                @[name] = utils.wrap @[name], (fn, args...) =>
                    # 对应的编码含义见: http://www.w3schools.com/tags/av_prop_readystate.asp
                    # 小于3认为还没有加载足够数据去播放。
                    if audio.readyState < 3
                        handle = () =>
                            fn.apply(@, args)
                            audio.off('canplay', handle)
                        audio.on('canplay', handle)
                    else
                        fn.apply(@, args)
                    @

        play: () ->
            @audio.play()
            @

        pause: () ->
            @audio.pause()
            @

        stop: () ->
            @setCurrentPosition(0).pause()

        setUrl: (url = '') ->
            @audio.src = url
            @audio.load()
            super(url)

        setVolume: (volume) ->
            @ unless 0 <= volume <= 100
            @audio.volume = volume / 100
            super(volume)

        setMute: (mute) ->
            mute = !!mute
            @audio.muted = mute
            super(mute)

        # audio没有loadedmetadata时, 会报INVALID_STATE_ERR。
        # 相关讨论可参考: https://github.com/johndyer/mediaelement/issues/243
        # 因此需要_needCanPlay的包装。
        setCurrentPosition: (ms) ->
            try
                @audio.currentTime = ms / 1000
            catch err
                console?.error(err)
            @play()
            @

        getCurrentPosition: () ->
            @audio.currentTime * 1000

        getLoadedPercent: () ->
            audio = @audio
            duration = audio.duration
            buffered = audio.buffered
            bl = buffered.length
            be = 0 # buffered end

            # 有多个缓存区间时, 查找当前缓冲使用的区间, 浏览器会自动合并缓冲区间。
            while bl--
                if buffered.start(bl) <= audio.currentTime <= buffered.end(bl)
                    be = buffered.end(bl)
                    break

            # 修复部分浏览器出现buffered end > duration的异常。
            be = if be > duration then duration else be
            duration and (be / duration).toFixed(2) * 1 or 0

        getTotalTime: () ->
            duration = @audio.duration
            # loadstart前duration为NaN。
            duration and duration * 1000 or 0

    AudioCore
) ->
    if typeof exports is 'object'
        module.exports = factory()
    else if typeof define is 'function' and define.amd
        define([
            'muplayer/core/cfg'
            'muplayer/core/utils'
            'muplayer/core/engines/engineCore'
            'muplayer/lib/modernizr.audio'
        ], factory)
    else
        root._mu.AudioCore = factory(
            _mu.cfg
            _mu.utils
            _mu.EngineCore
            _mu.Modernizr
        )
