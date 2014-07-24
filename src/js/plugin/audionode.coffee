do (root = this, factory = () ->
    class AudioNode
        constructor: (options) ->
            unless AudioContext
                return throw new Error('浏览器暂不支持Web Audio API :(')

            @opts = opts = $.extend({}, @defaults, options)

            unless opts.input
                return throw new Error('input是必填的初始化参数！')

            @context = context = new AudioContext()

            input = opts.input
            if input instanceof Audio
                @input = context.createMediaElementSource(input)
            else
                @input = input
            @output = opts.output or context.destination

        connect: () ->
            @output.connect.apply(@output, arguments);

        disconnect: () ->
            @output.disconnect(0)
) ->
    if typeof exports is 'object'
        module.exports = factory()
    else if typeof define is 'function' and define.amd
        define([
            'muplayer/lib/AudioContextMonkeyPatch'
        ], factory)
    else
        root._mu.AudioNode = factory()
