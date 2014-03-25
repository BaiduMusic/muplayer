do (root = this, factory = (cfg, utils, Events, Playlist, Engine) ->
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
            mode: 'loop'
            mute: false
            volume: 80

        ###*
         * Player初始化方法
         * @param {Object} options <table class="sub-params">
         *  <tr>
         *    <th>选项</th>
         *    <th>说明</th>
         *  </tr>
         *  <tr>
         *    <td>mode</td>
         *    <td>默认值: 'loop'。加入播放器的歌曲列表的播放顺序逻辑，可选值为 'loop'（循环播放），'list'（列表播放，该列表播放到最后一首或第一首后则停止播放），'single'（单曲播放），'random'（单曲随机），'list-random'（列表随机，与random的区别是保证已随机过的列表中歌曲均播放一次后，再对列表随机重置）。</td>
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
         *    <td>engine</td>
         *    <td>初始化Engine，根据传入的engines来指定具体使用FlashCore还是AudioCore来接管播放，当然也可以传入内核列表，Engine会内核所支持的音频格式做自适应。这里只看一下engines参数的可能值（其他参数一般无需配置，如有需要请查看engine.coffee的源码）：
         *    <pre>
         *    engines: [{<br>
         *    <span class="ts"></span>constructor: 'FlashCore',<br>
         *    <span class="ts"></span>args: { // 初始化FlashCore的参数<br>
         *    <span class="ts2"></span>swf: '../dist/swf/fmp.swf' // 对应的swf文件路径<br>
         *    <span class="ts"></span>}<br>
         *    }, {<br>
         *    <span class="ts"></span>constructor: 'AudioCore'<br>
         *    }]
         *    </pre>
         *    </td>
         *  </tr></table>
        ###
        constructor: (options) ->
            if instance
                return instance
            instance = @

            @opts = opts = $.extend(Player.defaults, options)

            @playlist = new Playlist()
            @playlist.setMode(opts.mode)
            @_initEngine(new Engine(opts.engine))
            @setMute(opts.mute)
            @setVolume(opts.volume)

        _initEngine: (engine) ->
            @engine = engine

            # 事件参考: http://www.whatwg.org/specs/web-apps/current-work/multipage/the-video-element.html#mediaevents
            # 原则上派发的事件应保持和HTML5 Audio规范一致。
            engine.on(EVENTS.STATECHANGE, (e) =>
                st = e.newState
                @trigger(st)
                if st is STATES.END
                    @next(true)
            ).on(EVENTS.POSITIONCHANGE, (pos) =>
                @trigger('timeupdate', pos)
            ).on(EVENTS.PROGRESS, (progress) =>
                @trigger('progress', progress)
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

            # XXX: 应该在_fetch中决定是否发起选链。
            # 即是否从cache中取, 是否setUrl都是依据_fetch的实现去决定。
            # 如果继承时覆盖重写_fetch, 这些都要自己权衡。
            @_fetch().done () ->
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
            if @getSongsNum() and @playlist.prev()
                @trigger('player:prev', {
                    cur: cur
                })
                return @play()
            @stop()

        ###*
         * 播放下一首歌。参数auto是布尔值，代表是否是因自动切歌而触发的（比如因为一首歌播放完会自动触发next方法，这时auto为true，其他主动调用auto应为undefined）。
         * 会派发 <code>player:next</code> 事件，事件参数：
         * <pre>auto // 是否为自动切歌
         * cur  // 调用next时正在播放的歌曲</pre>
         * @return {player}
        ###
        next: (auto) ->
            cur = @getCur()
            if @getSongsNum() and @playlist.next()
                @trigger('player:next', {
                    auto: auto,
                    cur: cur
                })
                return @play()
            @stop()

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
            if sid
                pl.setCur(sid)
            else if @getSongsNum()
                pl.setCur(pl.list[0])
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
