do (root = @, factory = (cfg, utils, Events, Playlist, Engine) ->
    {EVENTS, STATES} = cfg.engine
    time2str = utils.time2str

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
         *    <span class="ts"></span>constructor: 'FlashMP3Core',<br>
         *    <span class="ts"></span>args: { // 初始化FlashMP3Core的参数<br>
         *    <span class="ts2"></span>swf: 'muplayer_mp3.swf' // 对应的swf文件路径<br>
         *    <span class="ts"></span>}<br>
         *    }, {<br>
         *    <span class="ts"></span>constructor: 'FlashMP4Core',<br>
         *    <span class="ts"></span>args: { // 初始化FlashMP4Core的参数, FlashMP4Core支持m4a格式的音频文件<br>
         *    <span class="ts2"></span>swf: 'muplayer_mp4.swf' // 对应的swf文件路径<br>
         *    <span class="ts"></span>}<br>
         *    }, {<br>
         *    <span class="ts"></span>constructor: 'AudioCore'<br>
         *    }]
         *    </pre>
         *    </td>
         *  </tr></table>
        ###
        constructor: (options) ->
            @opts = opts = $.extend({}, Player.defaults, options)

            baseDir = opts.baseDir
            if baseDir is false
                baseDir = ''
            else unless baseDir
                throw "baseDir must be set! Usually, it should point to the MuPlayer's dist directory."
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

        _initEngine: (engine) ->
            @engine = engine.on(EVENTS.STATECHANGE, (e) =>
                st = e.newState
                @trigger('player:statechange', e)
                @trigger(st)
                if st is STATES.END
                    @next(true)
            ).on(EVENTS.POSITIONCHANGE, (pos) =>
                @trigger('timeupdate', pos)
            ).on(EVENTS.PROGRESS, (progress) =>
                @trigger('progress', progress)
            ).on(EVENTS.ERROR, (e) =>
                @trigger('error', e)
            )

        ###*
         * 若播放列表中有歌曲就开始播放。会派发 <code>player:play</code> 事件。
         * @param {Number} startTime 指定歌曲播放的起始位置，单位：毫秒。
         * @return {player}
        ###
        play: (startTime) ->
            startTime = ~~startTime
            def = $.Deferred()
            engine = @engine

            play = () =>
                if startTime
                    engine.setCurrentPosition(startTime)
                else
                    engine.play()
                @trigger('player:play', startTime)
                def.resolve()

            st = @getState()
            # 只有如下3种情况会触发_fetch选链：
            # 1) 内核首次使用 (STATES.NOT_INIT) 或被reset过 (STATES.STOP)
            # 2) 上一首歌播放完成自动触发下一首的播放 (STATES.END)
            # 3) 某些移动浏览器无交互时不能触发自动播放 (会被卡在STATES.BUFFERING)
            if st in [STATES.NOT_INIT, STATES.STOP, STATES.END] or st is STATES.BUFFERING and @curPos() is 0
                # XXX: 应该在_fetch中决定是否发起选链。
                # 即是否从cache中取, 是否setUrl都是依据_fetch的实现去决定。
                # 如果继承时覆盖重写_fetch, 这些都要自己权衡。
                @_fetch().done () =>
                    play()
            else
                play()

            return def.promise()

        ###*
         * 若player正在播放，则暂停播放 (这时，如果再执行play方法，则从暂停位置继续播放)。会派发 <code>player:pause</code> 事件。
         * @return {player}
        ###
        pause: ->
            @engine.pause()
            @trigger('player:pause')
            @

        ###*
         * 停止播放，会将当前播放位置重置。即stop后执行play，将从音频头部重新播放。会派发 <code>player:stop</code> 事件。
         * @return {player}
        ###
        stop: ->
            @engine.stop()
            @trigger('player:stop')
            @

        ###*
         * stop() + play()的快捷方式。
         * @return {player}
        ###
        replay: ->
            @stop().play()

        ###*
         * 播放前一首歌。会派发 <code>player:prev</code> 事件，事件参数：
         * <pre>cur // 调用prev时正在播放的歌曲</pre>
         * @return {player}
        ###
        prev: () ->
            cur = @getCur()
            @stop()
            if @getSongsNum() and @playlist.prev()
                @trigger('player:prev', {
                    cur: cur
                })
                @play()
            @

        ###*
         * 播放下一首歌。参数auto是布尔值，代表是否是因自动切歌而触发的（比如因为一首歌播放完会自动触发next方法，这时auto为true，其他主动调用auto应为undefined）。
         * 会派发 <code>player:next</code> 事件，事件参数：
         * <pre>auto // 是否为自动切歌
         * cur // 调用next时正在播放的歌曲</pre>
         * @return {player}
        ###
        next: (auto) ->
            cur = @getCur()
            @stop()
            if @getSongsNum() and @playlist.next()
                @trigger('player:next', {
                    auto: auto,
                    cur: cur
                })
                @play()
            @

        ###*
         * 获取当前歌曲（根据业务逻辑和选链_fetch方法的具体实现可以是音频文件url，也可以是标识id，默认直接传入音频文件url即可）。
         * 如果之前没有主动执行过setCur，则认为播放列表的第一首歌是当前歌曲。
         * @return {String}
        ###
        getCur: () ->
            pl = @playlist
            cur = pl.cur
            if not cur and @getSongsNum()
                cur = pl.list[0]
                pl.setCur(cur)
            cur + ''

        ###*
         * 设置当前歌曲。
         * @param {String} sid 可以是音频文件url，也可以是音频文件id（如果是文件id，则要自己重写_fetch方法，决定如何根据id获得相应音频的实际地址）。
         * @return {player}
        ###
        setCur: (sid) ->
            pl = @playlist
            if not sid and @getSongsNum()
                sid = pl.list[0]
            if sid and @_sid isnt sid
                pl.setCur(sid)
                @_sid = sid
                @stop()
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
         * 将音频资源添加到播放列表
         * @param {String|Array} sid 要添加的单曲资源或标识，为数组则代表批量添加。会派发 <code>player:add</code> 事件。
         * @return {player}
        ###
        add: (sid) ->
            if sid
                @playlist.add(sid)
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
        reset: () ->
            @playlist.reset()
            @engine.reset()
            @trigger('player:reset')
            @

        ###*
         * 获取播放内核当前状态。所有可能状态值参见 <code>cfg.coffee</code> 中的 <code>engine.STATES</code> 声明。
         * @return {String}
        ###
        getState: ->
            @engine.getState()

        ###*
         * 设置当前播放资源的url。一般而言，这个方法是私有方法，供_fetch等内部方法中调用，客户端无需关心。
         * 但出于调试和灵活性的考虑，依然之暴露为公共方法。
         * @param {String} url
         * @return {player}
        ###
        setUrl: (url) ->
            @engine.setUrl(url)
            @trigger('player:setUrl', url)
            @

        ###*
         * 获取当前播放资源的url。
         * @return {String}
        ###
        getUrl: ->
            @engine.getUrl()

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
        getSongsNum: () ->
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
        getMode: () ->
            @playlist.mode

        # 在基类的默认实现中将_fetch设计成Promise模式的接口调用似乎没有必要,
        # 但对于依赖API远程调用进行歌曲异步选链的场景下, Promise的处理无疑更具灵活性。
        # XXX: 如要实现自己的API选链逻辑，请务必重写_fetch方法。
        _fetch: () ->
            def = $.Deferred()
            if @getUrl() is @getCur()
                def.resolve()
            else
                setTimeout(() =>
                    @setUrl(@getCur())
                    def.resolve()
                , 0)
            def.promise()

    Events.mixTo(Player)
    Player
) ->
    if typeof exports is 'object'
        module.exports = factory()
    else if typeof define is 'function' and define.amd
        define([
            'muplayer/core/cfg'
            'muplayer/core/utils'
            'muplayer/lib/events'
            'muplayer/core/playlist'
            'muplayer/core/engines/engine'
        ], factory)
    else
        root._mu.Player = factory(
            root._mu.cfg
            root._mu.utils
            root._mu.Events
            root._mu.Playlist
            root._mu.Engine
        )
