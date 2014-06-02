do (root = this, factory = (cfg) ->
    utils = {}

    StrProto = String.prototype
    NumProto = Number.prototype
    ObjProto = Object.prototype
    ArrayProto = Array.prototype

    push = ArrayProto.push
    hasOwnProperty = ObjProto.hasOwnProperty
    toString = ObjProto.toString

    for name in ['Arguments', 'Function', 'String', 'Number', 'Date', 'RegExp']
        utils['is' + name] = do (name=name) ->
            (obj) ->
                toString.call(obj) == '[object ' + name + ']';

    unless $.isFunction(StrProto.startsWith)
        StrProto = (str) ->
            @slice(0, str.length) is str

    unless $.isFunction(StrProto.endsWith)
        StrProto = (str) ->
            return @slice(-str.length) is str

    # ref: http://stackoverflow.com/questions/10470810/javascript-tofixed-bug-in-ie6
    # 注意, 返回值是String, 如需转换成Number, 可以乘以1。
    NumProto.toFixed = (n) ->
        pow = Math.pow(10, n)
        fixed = (Math.round(@ * pow) / pow).toString()
        return fixed if n is 0
        fixed += '.' if fixed.indexOf('.') < 0
        padding = n + 1 - (fixed.length - fixed.indexOf('.'))
        while padding--
            fixed += '0'
        fixed

    $.extend utils, {
        isEmpty: (obj) ->
            unless obj? then return true
            if $.isArray(obj) or @isString(obj)
                return obj.length is 0
            for key in obj
                if @has(obj, key) then return false
            true

        isBoolean: (obj) ->
            obj is true or obj is false or toString.call(obj) is '[object Boolean]'

        has: (obj, key) ->
            hasOwnProperty.call(obj, key)

        random: (min, max) ->
            unless max
                max = min
                min = 0
            min + Math.floor(Math.random() * (max - min + 1))

        shuffle: (list) ->
            i = 0
            shuffled = []
            for item in list
                rand = @random(i++)
                shuffled[i - 1] = shuffled[rand]
                shuffled[rand] = item
            shuffled

        clone: (obj) ->
            unless $.isPlainObject(obj) then obj
            if $.isArray(obj) then obj.slice() else $.extend({}, obj)

        time2str: (time) ->
            r = []
            floor = Math.floor

            time = Math.round(time)
            hour = floor(time / 3600)
            minute = floor((time - 3600 * hour) / 60)
            second = time % 60

            pad = (source, length) =>
                pre = ''
                nagative = ''
                nagative = '-' if source < 0
                str = String(Math.abs(source))
                if str.length < length
                    pre = new Array(length - str.length + 1).join('0')
                nagative + pre + str

            r.push(hour) if hour
            r.push(pad(minute, 2))
            r.push(pad(second, 2))
            r.join(':')

        # ref: http://yuilibrary.com/yui/docs/api/classes/YUI.html#method_namespace
        # @param {String} namespace* One or more namespaces to create.
        # @return {Object} Reference to the last namespace object created
        # 示例:
        #    Creates `_mu.property.package`.
        #    namespace('property.package');
        namespace: () ->
            a = arguments
            period = '.'
            for arg in a
                o = cfg.namespace
                if arg.indexOf(period) > -1
                    d = arg.split(period)
                    [i, l] = [0, d.length]
                    while i < l
                        o[d[i]] = o[d[i]] or {}
                        o = o[d[i]]
                        i++
                else
                    o[arg] = o[arg] or {}
                    o = o[arg]
            o

        # 参考underscore
        wrap: (func, wrapper) ->
            () ->
                args = [func]
                push.apply(args, arguments)
                wrapper.apply(@, args)

        # 获得资源的绝对路径
        # 参考: http://grack.com/blog/2009/11/17/absolutizing-url-in-javascript/
        toAbsoluteUrl: (url) ->
            div = document.createElement('div')
            div.innerHTML = '<a></a>'
            div.firstChild.href = url
            div.innerHTML = div.innerHTML
            div.firstChild.href
    }

    utils
) ->
    if typeof exports is 'object'
        module.exports = factory()
    else if typeof define is 'function' and define.amd
        define(['muplayer/core/cfg'], factory)
    else
        root._mu.utils = factory(root._mu.cfg)
