do (root = @, factory = (cfg, utils, EngineCore, Modernizr) ->
    win = window
    {TYPES, EVENTS, STATES, ERRCODE} = cfg.engine

    class AudioCore extends EngineCore
        @defaults:
            # Audio是否可以播放的置信度, 可选值是maybe, probably或空字符。
            # 参考: http://www.whatwg.org/specs/web-apps/current-work/multipage/the-video-element.html#dom-navigator-canplaytype
            confidence: 'maybe'
            preload: false
            autoplay: false
            needPlayEmpty: true
            emptyMP3: 'empty.mp3'
        _supportedTypes: []
        engineType: TYPES.AUDIO

        constructor: (options) ->
            @opts = $.extend({}, AudioCore.defaults, options)
            @opts.emptyMP3 = @opts.baseDir + @opts.emptyMP3
            opts = @opts

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
            audio.loop = false
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
            @setState(STATES.NOT_INIT)
            @_initEvents()

            # 用于HACK Audio在IOS上的限制, 参考: http://www.ibm.com/developerworks/library/wa-ioshtml5/
            if opts.needPlayEmpty
                playEmpty = =>
                    # 当前没有set过url时才set一个空音频，以免影响到成功自动播放的后续交互
                    unless @getUrl()
                        @setUrl(opts.emptyMP3).play()
                    win.removeEventListener('touchstart', playEmpty, false)
                win.addEventListener('touchstart', playEmpty, false)

        _test: ->
            if not Modernizr.audio or not @_supportedTypes.length
                return false
            true

        # 事件类型参考: http://www.w3schools.com/tags/ref_eventattributes.asp
        _initEvents: ->
            self = @
            { audio, trigger } = @
            [ errorTimer, progressTimer, canPlayThrough ]  = [ null, null, false ]

            @trigger = (type, listener) ->
                trigger.call(self, type, listener) if self.getUrl() isnt self.opts.emptyMP3

            progress = (per) ->
                self.trigger(EVENTS.PROGRESS, per or self.getLoadedPercent())

            audio.on('loadstart', ->
                canPlayThrough = false
                # 某些IOS浏览器及Chrome会因歌曲缓存导致progress不被触发，此时使用
                # “万能的”计时器轮询计算加载进度
                progressTimer = setInterval( ->
                    if audio.readyState > 1
                        return clearInterval(progressTimer)
                    progress()
                , 50)
                self.setState(STATES.PREBUFFER)
            ).on('playing', ->
                clearTimeout(errorTimer)
                self.setState(STATES.PLAYING)
            ).on('pause', ->
                self.setState(self.getCurrentPosition() and STATES.PAUSE or STATES.STOP)
            ).on('ended', ->
                self.setState(STATES.END)
            ).on('error', (e) ->
                errorTimer = setTimeout( ->
                    self.trigger(EVENTS.ERROR, e.target.error.code)
                    self.setState(STATES.END)
                , 2000)
            ).on('waiting', ->
                unless canPlayThrough
                    self.setState(STATES.PREBUFFER)
            ).on('loadeddata', ->
                unless canPlayThrough
                    self.setState(STATES.BUFFERING)
            ).on('canplaythrough', ->
                unless canPlayThrough
                    canPlayThrough = true
                    self.setState(STATES.CANPLAYTHROUGH)
            ).on('timeupdate', ->
                self.trigger(EVENTS.POSITIONCHANGE, self.getCurrentPosition())
            ).on('progress', (e) ->
                clearInterval(progressTimer)
                # firefox 3.6 implements e.loaded/total (bytes)
                loaded = e.loaded or 0
                total = e.total or 1
                progress(loaded and (loaded / total).toFixed(2) * 1)
            )

        _needCanPlay: (fnames) ->
            audio = @audio
            for name in fnames
                @[name] = utils.wrap @[name], (fn, args...) =>
                    # 对应的编码含义见: http://www.w3schools.com/tags/av_prop_readystate.asp
                    # 小于3认为还没有加载足够数据去播放。
                    if audio.readyState < 3
                        handle = =>
                            fn.apply(@, args)
                            audio.off('canplay', handle)
                        audio.on('canplay', handle)
                    else
                        fn.apply(@, args)
                    @

        play: ->
            @audio.play()
            @

        pause: ->
            @audio.pause()
            @

        stop: ->
            # FIXED: https://github.com/Baidu-Music-FE/muplayer/issues/2
            # 不能用setCurrentPosition(0)，似乎是因为_needCanPlay包装器使
            # 该方法成为了非同步方法, 导致执行顺序和预期不符。
            try
                @audio.currentTime = 0
            catch
            finally
                @pause()
            @

        setUrl: (url) ->
            if url
                @audio.src = url
                @audio.load()
            super(url)

        setVolume: (volume) ->
            @audio.volume = volume / 100
            super(volume)

        setMute: (mute) ->
            @audio.muted = mute
            super(mute)

        # audio没有loadedmetadata时, 会报INVALID_STATE_ERR。
        # 相关讨论可参考: https://github.com/johndyer/mediaelement/issues/243
        # 因此需要_needCanPlay的包装。
        setCurrentPosition: (ms) ->
            try
                @audio.currentTime = ms / 1000
            catch
            finally
                @play()
            @

        getCurrentPosition: ->
            @audio.currentTime * 1000

        getLoadedPercent: ->
            audio = @audio
            buffered = audio.buffered
            bl = buffered.length
            be = 0 # buffered end

            # 有多个缓存区间时, 查找当前缓冲使用的区间, 浏览器会自动合并缓冲区间。
            while bl--
                if buffered.start(bl) <= audio.currentTime <= buffered.end(bl)
                    be = buffered.end(bl)
                    break

            duration = @getTotalTime() / 1000

            # 修复部分浏览器出现buffered end > duration的异常。
            be = if be > duration then duration else be
            duration and (be / duration).toFixed(2) * 1 or 0

        getTotalTime: ->
            {duration, buffered} = @audio
            bl = buffered.length

            # duration为NaN的情况。
            if not isFinite(duration) and bl > 0
                duration = buffered.end(--bl)

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
