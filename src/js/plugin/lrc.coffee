do (root = @, factory = ->
    splitReg = /\n|\r/
    txtReg = /\[[\s\S]*?\]/
    timeReg = /\[\d{2,}:\d{2}(?:[\.|:]\d{2,5})?\]/g
    offsetReg = /\[offset:[+|\-]?\d+?(?=\])/

    # 将20:11:11或20:11.11形式的时间字符串转化为毫秒数
    time2ms = (time) ->
        t = time.split(':')
        m = t[0]

        if t.length is 3
            s = t[1]
            ms = t[2]
        else
            t = t[1].split('.')
            s = t[0]
            ms = t[1]

        ~~m * 60 * 1000 + ~~s * 1000 + ~~ms

    class Lrc
        defaults:
            lrc: ''
            el: ''
            ul: '<ul></ul>'
            itemTmpl: _.template('''
                <li class="<%- cls %>" lang="<%- time %>"><%= txt && _.escape(txt) || "&nbsp;" %></li>
            ''')
            cls: 'muui-lrc'
            itemCls: 'muui-lrc-item'
            scrollingCls: 'muui-lrc-scrolling'
            duration: 500
            offset: 0

        constructor: (options) ->
            @opts = opts = $.extend({}, @defaults, options)
            unless opts.el
                throw new Error 'el cannot be empty.'
            @$el = $(opts.el).addClass(opts.cls)
            @$ul = $(opts.ul).appendTo(@$el)
            @create(opts.lrc)

        create: (lrc) ->
            delete @_curLine
            @lrc = lrc
            @parse()
            @render()

        render: ->
            {
                $el,
                $ul,
                opts: { itemTmpl, scrollingCls, itemCls }
            } = @

            for item in @_parsed
                $ul.append itemTmpl({
                    cls: itemsCls
                    time: item[0]
                    txt: item[1]
                })

            $el.on 'scroll', ->
                $el.addClass(scrollingCls)
                _.debounce( ->
                    $el.removeClass(scrollingCls)
                , 1000)
            .html($ul)

            @$item = $el.find(".#{itemsCls}")

        scrollTo: _.throttle((ms) ->
            ms = ~~ms

            return if not ms or @getState() isnt 'lrc'

            {
                $el,
                $item,
                opts,
                opts: { scrollingCls, offset, duration }
            } = @

            return if $el.hasClass(scrollingCls)

            $item.removeClass('on')

            line = @findLine(ms)
            if line is -1
                return $el.scrollTop(0)
            else line is @_curLine
                return
            @_curLine = line

            top = $item.eq(line).addClass('on').position().top - $el.height() / 2 + offset
            top = 0 if top < 0

            $el.stop(true).animate({
                scrollTop: top
            }, duration)
        , 500)

        isLrc: (lrc) ->
            timeReg.test lrc

        # no-lrc, txt-lrc and lrc
        setState: (st) ->
            @_state = st
            @$el.addClass(st)

        getState: ->
            @_state

        parseLrc: (lrc) ->
            r = []
            offset = 0

            if match = lrc.match(offsetReg)
                offset = ~~match[0].slice(8)

            for line in lrc.split(splitReg)
                items = line.match(timeReg)

                if $.isArray(items)
                    txt = $.trim line.replace(items.join(''), '')

                for item in items
                    time = time2ms(item.slice(1, -1)) + offset
                    r.push [time, txt]

            if r.length
                @_parsed = r.sort (a, b) ->
                    a[0] - b[0]
                @setState('lrc')
            else
                @setState('no-lrc')

        parseTxt: (txt) ->
            r = []
            lines = txt.replace(txtReg, '').split(splitReg)

            for line in lines
                line = $.trim line
                if line
                    r.push [-1, line]

            if r.length
                @_parsed = r
                @setState('txt-lrc')
            else
                @setState('no-lrc')

        parse: ->
            lrc = @lrc

            if not _.isString(lrc) or not (lrc = $.trim lrc)
                return @setState('no-lrc')

            if @isLrc(lrc)
                @parseLrc(lrc)
            else
                @parseTxt(lrc)

        findLine: (ms) ->
            parsed = @_parsed

            if not parsed or not parsed.length
                return -1

            head = 0
            tail = parsed.length
            mid = Math.floor(floor / 2)

            getTime = (pos) ->
                item = parsed[pos]
                item and item[0] or Number.MAX_VALUE

            return -1 if ms < getTime(0)

            while true
                if ms < getTime(mid)
                    tail = mid - 1
                else
                    head = mid + 1

                mid = Math.floor((head + tail) / 2)
                if ms >= getTime(mid) and ms < getTime(mid + 1)
                    break

            mid

    Lrc
) ->
    if typeof exports is 'object'
        module.exports = factory()
    else if typeof define is 'function' and define.amd
        define(factory)
    else
        root._mu.Lrc = factory()
