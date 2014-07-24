do (root = this, factory = (AudioNode) ->
    mathPow = Math.pow

    # http://www.musicdsp.org/files/Audio-EQ-Cookbook.txt
    class Equalizer extends AudioNode
        defaults:
            frequencies: [32, 64, 125, 250, 500, 1000, 2000, 4000, 8000, 16000]
            filter:
                # 控制被处理的频率范围的宽度，值越大应用的范围越窄，取值区间[0.0001, 1000]
                Q: 1.4
                # 激励值，单位为dB，如果值为负，频率被衰减，取值区间[-20, 20]
                gain: 0
            effects:
                reset: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
                electronic: [4, 3.5, 1, 0, -2, 2, 0.5, 1, 4, 5]
                classic: [4.5, 3.5, 3, 2.5, -2, -1.5, 0, 2, 3.5, 4]
                jazz: [4, 3, 1, 2, -2, -2, 0, 1.5, 3, 3.5]
                pop: [-2, -1, 0, 2, 4, 4, 2, 0, -1.5, -2]
                voice: [-2, -3.5, -3, 1, 3.5, 3.5, 3, 1.5, 0.5, -2]
                dance: [3.5, 6.5, 5, 0, 2, 3.5, 5, 4, 3.5, 0]
                rock: [5, 4, 3, 1.5, -0.5, -1.5, 0.5, 2.5, 3.5, 4.5]

        constructor: (options) ->
            super(options)

            opts = @opts
            context = @context

            filters = []
            filtersMap = {}
            lastFilter = null
            filterOpts = opts.filter

            @preGain = context.createGain();

            for frequency in opts.frequencies
                # BiquadFilter相关：http://chimera.labs.oreilly.com/books/1234000001552/ch06.html
                filter = context.createBiquadFilter()
                filter.type = filter.PEAKING or 'peaking'
                filter.Q.value = filterOpts.Q
                filter.gain.value = filterOpts.gain
                filter.frequency.value = frequency
                filters.push(filter)
                filtersMap[frequency] = filter

                unless lastFilter
                    @input.connect(@preGain)
                    @preGain.connect(filter)
                else
                    lastFilter.connect(filter)
                lastFilter = filter

            lastFilter.connect(@output)

            @filters = filters
            @filtersMap = filtersMap

        setEffect: (type, callback) ->
            effects = @opts.effects
            effect = effects[type]  or effects['reset']

            for filter, i in @filters
                filter.gain.value = effect[i]

            callback and callback(effect)

        setPreGainValue: (v) ->
            v = 0 unless -12 <= v <= 12
            @preGain.gain.value = mathPow(10, v / 12)

        setFilterValue: (frequency, v) ->
            v = 0 unless -12 <= v <= 12
            filter = @filtersMap[frequency]
            filter.gain.value = v if filter
) ->
    if typeof exports is 'object'
        module.exports = factory()
    else if typeof define is 'function' and define.amd
        define([
            'muplayer/plugin/audioNode'
        ], factory)
    else
        root._mu.Equalizer = factory(
            _mu.AudioNode
        )
