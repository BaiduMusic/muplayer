do (root = @, factory = (utils, Events) ->
    class Playlist
        constructor: (options) ->
            @opts = $.extend({}, @defaults, options)
            @reset()

        reset: ->
            @cur = ''
            if $.isArray(@list)
                @list.length = 0
            else
                @list = []

        _resetListRandom: (index) ->
            if @mode is 'list-random'
                index = index or 0
                @_listRandomIndex = index
                @_listRandom = utils.shuffle([0...@list.length])
                @cur = @list[@_listRandom[index]]

        _formatSid: (sids) ->
            absoluteUrl = @opts.absoluteUrl

            # 根据配置，决定是否转换为绝对路径的方式。
            # 同时保证将存储在播放列表中的sid统一转成字符串格式，
            # 有利于减少对API返回的值特例处理。
            format = (sid) ->
                absoluteUrl and utils.toAbsoluteUrl(sid) or '' + sid

            $.isArray(sids) and (format(sid) for sid in sids when sid) or format(sids)

        setMode: (mode) ->
            if mode in [
                'single'
                'random'
                'list-random'
                'list'
                'loop'
            ] then @mode = mode
            @_resetListRandom()

        add: (sid, unshift = true) ->
            sid = @_formatSid(sid)

            # 剔除重复sid, 保证列表是一个set
            @remove(sid)

            if $.isArray(sid) and sid.length
                @list = unshift and sid.concat(@list) or @list.concat(sid)
            else if sid
                @list[unshift and 'unshift' or 'push'](sid)

            @trigger('playlist:add', sid)
            @_resetListRandom()

        remove: (sid) ->
            remove = (sid) =>
                i = $.inArray(sid, @list)
                unless i is -1
                    @list.splice(i, 1)

            sid = @_formatSid(sid)
            if $.isArray(sid)
                remove(id) for id in sid
            else
                remove(sid)

            @trigger('playlist:remove', sid)
            @_resetListRandom()

        prev: =>
            list = @list
            i = $.inArray(@cur, list)
            i = 0 if i is -1
            l = list.length
            prev = i - 1

            switch @mode
                when 'single' then prev = i
                when 'random' then prev = utils.random(0, l - 1)
                when 'list'
                    if i = 0
                        @cur = ''
                        # false作为返回值以终止循环播放，详见player的next方法
                        return false
                when 'list-random'
                    i = @_listRandomIndex--
                    prev = i - 1
                    if i is 0
                        prev = l - 1
                        @_resetListRandom(prev)
                    return @cur = list[@_listRandom[prev]]
                when 'loop'
                    prev = l - 1 if i is 0

            @cur = list[prev]

        next: =>
            list = @list
            i = $.inArray(@cur, list)
            i = 0 if i is -1
            l = list.length
            next = i + 1

            switch @mode
                when 'single' then next = i
                when 'random' then next = utils.random(0, l - 1)
                when 'list'
                    if i is l - 1
                        @cur = ''
                        return false
                when 'list-random'
                    i = @_listRandomIndex++
                    next = i + 1
                    if i is l - 1
                        next = 0
                        @_resetListRandom(next)
                    return @cur = list[@_listRandom[next]]
                when 'loop'
                    next = 0 if i is l - 1

            @cur = list[next]

        setCur: (sid) ->
            sid = @_formatSid(sid)
            unless sid in @list
                @add(sid)
            @cur = sid

    Events.mixTo(Playlist)
    Playlist
) ->
    if typeof exports is 'object'
        module.exports = factory()
    else if typeof define is 'function' and define.amd
        define([
            'muplayer/core/utils'
            'muplayer/lib/events'
        ], factory)
    else
        root._mu.Playlist = factory(
            _mu.utils
            _mu.Events
        )
