do (root = this, factory = (
    cfg, utils, Timer, Events, Playlist, Engine
) ->
    { EVENTS, STATES } = cfg.engine

    time2str = utils.time2str

    ctrl = (fname, auto) ->
        unless fname in ['prev', 'next']
            return @

        play = =>
            args =
                cur: @getCur()
            args.auto = auto if auto
            @trigger "player:#{fname}", args
            @stop(false).play()

        if @getSongsNum()
            pl = @playlist
            unless pl.cur
                play()
            else if pl[fname].call(pl, auto)
                play()
            else
                @trigger "player:#{fname}:fail", auto

        @

    ###*
     * muplayer的Player类（对应player.js）是对外暴露的接口，它封装了音频操作及播放列表（Playlist）逻辑，并屏蔽了对音频内核适配的细节对音频内核适配的细节。
     * <b>对一般应用场景，只需签出编译后的 <code>dist/js/player.min.js</code> 即可</b>。
     * 文档中 <code>player</code> 指代Player的实例。
    ###
    class Player
        instance = null

        @defaults:
            baseDir: "#{cfg.cdn}#{cfg.version}"
            mode: 'loop'
            mute: false
            volume: 80
            singleton: true
            absoluteUrl: true
            maxRetryTimes: 1
            maxWaitingTime: 4
            recoverMethodWhenWaitingTimeout: 'retry'

            # 在基类的默认实现中将fetch设计成Promise模式的接口调用似乎没有必要,
            # 但对于依赖API远程调用进行歌曲异步选链的场景下, Promise的处理无疑更具灵活性。
            # XXX: 如要实现自己的API选链逻辑，请务传入自己的fetch方法。
            fetch: ->
                def = $.Deferred()
                cur = @getCur()
                setTimeout( =>
                    @setUrl(cur)
                    def.resolve()
                , 0)
                def.promise()

        ###*
         * Player初始化方法
         * @param {Object} options <table class="sub-params">
         *  <tr>
         *    <th>选项</th>
         *    <th>说明</th>
         *  </tr>
         *  <tr>
         *    <td>baseDir</td>
         *    <td>必填选项，指向MuPlayer编译后的静态文件资源目录。默认指向同版本线上CDN文件目录，但建议指向自己签出的dist文件夹目录，以规避潜在的flash跨域警告。</td>
         *  </tr>
         *  <tr>
         *    <td>mode</td>
         *    <td>默认值: 'loop'。加入播放器的歌曲列表的播放顺序逻辑，可选值为 'loop'（循环播放），'list'（列表播放，该列表播放到最后一首或第一首后则停止播放），'single'（单曲播放），'random'（随机），'list-random'（列表随机，与random的区别是保证已随机过的列表中歌曲均播放一次后，再对列表随机重置）。</td>
         *  </tr>
         *  <tr>
         *    <td>mute</td>
         *    <td>默认值: false。是否静音。</td>
         *  </tr>
         *  <tr>
         *    <td>volume</td>
         *    <td>默认值: 80。播放音量，取值范围0 - 100。</td>
         *  </tr>
         *  <tr>
         *    <td>singleton</td>
         *    <td>默认值: true。初始化的Player实例是否是单实例。如果希望一个页面中有多个播放实例并存，可以设成false</td>
         *  </tr>
         *  <tr>
         *    <td>absoluteUrl</td>
         *    <td>默认值: true。播放音频的链接是否要自动转化成绝对地址。</td>
         *  </tr>
         *  <tr>
         *    <td>engines</td>
         *    <td>初始化Engine，根据传入的engines来指定具体使用FlashMP3Core还是AudioCore来接管播放，当然也可以传入内核列表，Engine会根据内核所支持的音频格式做自适应。这里只看一下engines参数的可能值（其他参数一般无需配置，如有需要请查看engine.coffee的源码）：
         *    <pre>
         *    [{<br>
         *    <span class="ts"></span>type: 'FlashMP3Core',<br>
         *    <span class="ts"></span>args: { // 初始化FlashMP3Core的参数<br>
         *    <span class="ts2"></span>swf: 'muplayer_mp3.swf' // 对应的swf文件路径<br>
         *    <span class="ts"></span>}<br>
         *    }, {<br>
         *    <span class="ts"></span>type: 'FlashMP4Core',<br>
         *    <span class="ts"></span>args: { // 初始化FlashMP4Core的参数, FlashMP4Core支持m4a格式的音频文件<br>
         *    <span class="ts2"></span>swf: 'muplayer_mp4.swf' // 对应的swf文件路径<br>
         *    <span class="ts"></span>}<br>
         *    }, {<br>
         *    <span class="ts"></span>type: 'AudioCore'<br>
         *    }]
         *    </pre>
         *    </td>
         *  </tr></table>
        ###
        constructor: (options) ->
            @opts = opts = $.extend({}, Player.defaults, options)
            @waitingTimer = new Timer(100)

            @_checkFrozen([
                'play', 'pause', 'stop', 'setCurrentPosition'
                'setVolume', 'setMute', 'next', 'prev', 'retry'
                '_startWaitingTimer'
            ])

            baseDir = opts.baseDir
            if baseDir is false
                baseDir = ''
            else unless baseDir
                throw new Error "baseDir must be set! Usually, it should point to the MuPlayer's dist directory."
            if baseDir and not baseDir.endsWith('/')
                baseDir = baseDir + '/'

            if opts.singleton
                if instance
                    return instance
                instance = @

            @playlist = new Playlist(absoluteUrl: opts.absoluteUrl)
            @playlist.setMode(opts.mode)
            @_initEngine(new Engine(
                baseDir: baseDir
                engines: opts.engines
            ))
            @setMute(opts.mute)
            @setVolume(opts.volume)
            @reset()

        _initEngine: (engine) ->
            self = @
            recover = @opts.recoverMethodWhenWaitingTimeout

            @engine = engine
            @engine.on(EVENTS.STATECHANGE, (e) ->
                st = e.newState
                self.trigger('player:statechange', e)
                self.trigger(st)
                if st is STATES.END
                    self._clearWaitingTimer().next(true)
            ).on(EVENTS.POSITIONCHANGE, (pos) ->
                pos = ~~pos
                return unless pos
                st = self.getState()
                if self.getUrl() and st in [
                    STATES.PLAYING, STATES.PREBUFFER,
                    STATES.BUFFERING, STATES.CANPLAYTHROUGH
                ]
                    self.trigger('timeupdate', pos)
                    self._startWaitingTimer()
            ).on(EVENTS.PROGRESS, (progress) ->
                self.trigger('progress', progress)
            ).on(EVENTS.ERROR, (e) ->
                console?.error?('error: ', e)
                self.trigger('error', e)
            ).on(EVENTS.WAITING_TIMEOUT, ->
                if recover in ['retry', 'next']
                    self[recover]()
                self.trigger('player:waiting_timeout')
            )

        retry: ->
            if @_retryTimes < @opts.maxRetryTimes
                @_retryTimes++
                url = @getUrl()
                ms = @engine.getCurrentPosition()
                @pause().setUrl(url).engine.setCurrentPosition(ms)
                @_startWaitingTimer().trigger('player:retry', @_retryTimes)
            else
                @_retryTimes = 0
                @trigger('player:retry:max')
            @

        ###*
         * 若播放列表中有歌曲就开始播放。会派发 <code>player:play</code> 事件。
         * @param {Number} startTime 指定歌曲播放的起始位置，单位：毫秒。
         * @return {player}
        ###
        play: (startTime) ->
            self = @
            engine = @engine
            def = $.Deferred()

            play = ->
                unless self._frozen
                    self._startWaitingTimer()
                    if self.getUrl()
                        engine.play()
                        if $.isNumeric startTime
                            engine.setCurrentPosition(startTime)
                def.resolve()

            st = @getState()
            # 只有如下2种情况会触发opts.fetch选链：
            # 1) 内核首次使用或被reset过 (STATES.STOP)
            # 2) 上一首歌播放完成自动触发下一首的播放 (STATES.END)
            if st in [STATES.STOP, STATES.END] or not @getUrl()
                # XXX: 应该在opts.fetch中决定是否发起选链。
                # 是从cache中取音频链接地址，还是发起选链请求，
                # 及setUrl的时机都是依据opts.fetch的实现决定。
                # 如果继承时需传入自己的fetch实现，这些都要自己权衡。
                @trigger('player:fetch:start')
                @opts.fetch.call(@).done ->
                    play()
                    self.trigger('player:fetch:done')
                .fail (err) ->
                    self.trigger('player:fetch:fail', err)
            else
                play()

            self.trigger('player:play', startTime)

            return def.promise()

        ###*
         * 若player正在播放，则暂停播放 (这时，如果再执行play方法，则从暂停位置继续播放)。会派发 <code>player:pause</code> 事件。
         * @return {player}
        ###
        pause: (trigger = true) ->
            @engine.pause()
            @_clearWaitingTimer()
            @trigger('player:pause') if trigger
            @

        ###*
         * 停止播放，会将当前播放位置重置。即stop后执行play，将从音频头部重新播放。会派发 <code>player:stop</code> 事件。
         * @return {player}
        ###
        stop: (trigger = true) ->
            @engine.stop()
            @_clearWaitingTimer()
            @trigger('player:stop') if trigger
            @

        ###*
         * stop() + play()的快捷方式。
         * @return {player}
        ###
        replay: ->
            @stop(false).play()

        ###*
         * 播放前一首歌。会派发 <code>player:prev</code> 事件，事件参数：
         * <pre>cur // 调用prev时正在播放的歌曲</pre>
         * @return {player}
        ###
        prev: ->
            ctrl.apply @, ['prev']

        ###*
         * 播放下一首歌。参数auto是布尔值，代表是否是因自动切歌而触发的（比如因为一首歌播放完会自动触发next方法，这时auto为true，其他主动调用auto应为undefined）。
         * 会派发 <code>player:next</code> 事件，事件参数：
         * <pre>auto // 是否为自动切歌
         * cur // 调用next时正在播放的歌曲</pre>
         * @return {player}
        ###
        next: (auto) ->
            ctrl.apply @, ['next', auto]

        ###*
         * 获取当前歌曲（根据业务逻辑和选链opts.fetch方法的具体实现可以是音频文件url，也可以是标识id，默认直接传入音频文件url即可）。
         * 如果之前没有主动执行过setCur，则认为播放列表的第一首歌是当前歌曲。
         * @return {String}
        ###
        getCur: ->
            pl = @playlist
            cur = pl.cur
            if not cur and @getSongsNum()
                pl.cur = cur = pl.list[0]
            @_sid = '' + cur

        ###*
         * 设置当前歌曲。
         * @param {String} sid 可以是音频文件url，也可以是音频文件id（如果是文件id，则要实现自己的opts.fetch方法，决定如何根据id获得相应音频的实际地址）。
         * @return {player}
        ###
        setCur: (sid) ->
            sid = '' + sid
            pl = @playlist
            if not sid and @getSongsNum()
                sid = pl.list[0]
            if sid and @_sid isnt sid
                pl.setCur(sid)
                @_sid = sid
                @stop(false)
            @trigger('player:setCur', sid)
            @

        ###*
         * 当前播进度（单位秒）。
         * @return {Number}
        ###
        curPos: (format) ->
            pos = @engine.getCurrentPosition() / 1000
            if format then time2str(pos) else pos

        ###*
         * 单曲总时长（单位秒）。
         * @return {Number}
        ###
        duration: (format) ->
            duration = @engine.getTotalTime() / 1000
            if format then time2str(duration) else duration

        ###*
         * 将音频资源添加到播放列表，会派发 <code>player:add</code> 事件。
         * @param {String|Array} sid 要添加的单曲资源或标识，为数组则代表批量添加。
         * @param {Boolean} unshift sid被添加到播放列表中的位置，默认是true，代表往数组前面添加，为flase时表示往数组后添加。
         * @return {player}
        ###
        add: (sid, unshift = true) ->
            if sid
                @playlist.add(sid, unshift)
            @trigger('player:add', sid)
            @

        ###*
         * 从播放列表中移除指定资源，若移除资源后列表为空则触发reset。会派发 <code>player:remove</code> 事件。
         * @param {String|Array} sid 要移除的资源标识（与add方法参数相对应）。
         * @return {player}
        ###
        remove: (sid) ->
            if sid
                @playlist.remove(sid)
            unless @getSongsNum()
                @reset()
            @trigger('player:remove', sid)
            @

        ###*
         * 播放列表和内核资源重置。会派发 <code>player:reset</code> 事件。
         * 如有特别需要可以自行扩展，比如通过监听 <code>player:reset</code> 来重置相关业务逻辑的标志位或事件等。
         * @return {player}
        ###
        reset: ->
            delete @_sid
            @_retryTimes = 0
            @playlist.reset()
            @engine.reset()
            @trigger('player:reset')
            @stop(false)

        ###*
         * 销毁 <code>MuPlayer</code> 实例（解绑事件并销毁DOM）。
         * @return {player}
        ###
        destroy: ->
            @reset().off()
            @engine.destroy()
            @playlist.destroy()
            instance = null
            @

        ###*
         * 获取播放内核当前状态。所有可能状态值参见 <code>cfg.coffee</code> 中的 <code>engine.STATES</code> 声明。
         * @return {String}
        ###
        getState: ->
            @engine.getState()

        ###*
         * 设置当前播放资源的url。一般而言，这个方法是私有方法，供opts.fetch选链使用，客户端无需关心。
         * 但出于调试和灵活性的考虑，依然之暴露为公共方法。
         * @param {String} url
         * @return {player}
        ###
        setUrl: (url) ->
            return @ unless url
            @stop(false).engine.setUrl(url)
            @trigger('player:setUrl', url)
            @

        ###*
         * 获取当前播放资源的url。
         * @return {String}
        ###
        getUrl: ->
            @engine.getUrl()

        ###*
         * 根据后缀名获取当前播放资源的类型。
         * @return {String}
        ###
        getExt: ->
            utils.getExt @getUrl()

        ###*
         * 设置播放器音量。
         * @param {Number} volume 合法范围：0 - 100，0是静音。注意volume与mute不会相互影响，即便setVolume(0)，getMute()的结果依然维持不变。反之亦然。
        ###
        setVolume: (volume) ->
            @engine.setVolume(volume)
            @trigger('player:setVolume', volume)
            @

        ###*
         * 获取播放器音量。返回值范围：0 - 100
         * @return {Number}
        ###
        getVolume: ->
            @engine.getVolume()

        ###*
         * 设置是否静音。
         * @param {Boolean} mute true为静音，flase为不静音。
         * @return {player}
        ###
        setMute: (mute) ->
            @engine.setMute(mute)
            @trigger('player:setMute', mute)
            @

        ###*
         * 获取静音状态。
         * @return {Boolean}
        ###
        getMute: ->
            @engine.getMute()

        ###*
         * 检验内核是否支持播放指定的音频格式。
         * @param {String} type 标识音频格式（或音频文件后缀）的字符串，如'mp3', 'aac'等。
         * @return {Boolean}
        ###
        canPlayType: (type) ->
            @engine.canPlayType(type)

        ###*
         * 播放列表中的歌曲总数。这一个快捷方法，如有更多需求，可自行获取播放列表：player.playlist.list。
         * @return {Number}
        ###
        getSongsNum: ->
            @playlist.list.length

        ###*
         * 设置列表播放的模式。
         * @param {String} mode 可选值参见前文对初始化Player方法的options参数描述。
         * @return {player}
        ###
        setMode: (mode) ->
            @playlist.setMode(mode)
            @trigger('player:setMode', mode)
            @

        ###*
         * 获取列表播放的模式。
         * @return {String}
        ###
        getMode: ->
            @playlist.mode

        ###*
         * 获取当前engineType。
         * @return {String} [FlashMP3Core|FlashMP3Core|AudioCore]
        ###
        getEngineType: ->
            @engine.curEngine.engineType

        ###*
         * 设置冻结（冻结后MuPlayer实例的set方法及切歌方法失效）
         * @param {Boolean} frozen 是否冻结。
         * @return {player}
        ###
        setFrozen: (frozen) ->
            @_frozen = !!frozen
            @

        cheatPlayer: ->
            if @getEngineType() is 'AudioCore'
                @engine.curEngine._playEmpty()
            @

        _checkFrozen: (fnames) ->
            self = @
            for name in fnames
                self[name] = utils.wrap self[name], (fn, args...) ->
                    unless self._frozen
                        fn.apply(self, args)
                    self

        _startWaitingTimer: ->
            @waitingTimer.clear().after("#{@opts.maxWaitingTime} seconds", =>
                @engine.trigger(EVENTS.WAITING_TIMEOUT)
            ).start()
            @

        _clearWaitingTimer: ->
            @waitingTimer.clear()
            @

    Events.mixTo(Player)
    Player
) ->
    if typeof exports is 'object'
        module.exports = factory()
    else if typeof define is 'function' and define.amd
        define([
            'muplayer/core/cfg'
            'muplayer/core/utils'
            'muplayer/lib/Timer'
            'muplayer/lib/events'
            'muplayer/core/playlist'
            'muplayer/core/engines/engine'
        ], factory)
    else
        root._mu.Player = factory(
            _mu.cfg
            _mu.utils
            _mu.Timer
            _mu.Events
            _mu.Playlist
            _mu.Engine
        )
