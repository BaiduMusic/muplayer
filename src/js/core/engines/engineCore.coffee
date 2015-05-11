##
# EngineCore是FlashMP3Core, AudioCore等播放内核的基类
##
do (root = @, factory = (cfg, utils, Events) ->
    { EVENTS, STATES } = cfg.engine
    availableStates = (v for k, v of STATES)

    class EngineCore
        _supportedTypes: []

        getSupportedTypes: ->
            @_supportedTypes

        canPlayType: (type) ->
            type = 'm4a' if type is 'mp4a'
            $.inArray(type, @getSupportedTypes()) isnt -1

        reset: ->
            @stop()
            @_url = ''
            @_canPlayThrough = false
            @trigger(EVENTS.PROGRESS, 0)
            @trigger(EVENTS.POSITIONCHANGE, 0)
            @

        destroy: ->
            @reset().off()

        play: ->
            @

        pause: ->
            @

        stop: ->
            @

        setUrl: (url) ->
            @_url = url if url
            @

        getUrl: ->
            @_url

        setState: (st) ->
            st = STATES.END unless @getUrl()

            if st not in availableStates or st is @_state
                return

            if @_canPlayThrough and st in [
                STATES.PREBUFFER, STATES.BUFFERING
            ]
                return

            oldState = @_state
            @_state = st
            @trigger(EVENTS.STATECHANGE, {
                oldState: oldState
                newState: st
            })

        getState: ->
            @_state

        setVolume: (volume) ->
            @_volume = volume
            @

        getVolume: ->
            @_volume

        setMute: (mute) ->
            @_mute = mute
            @

        getMute: ->
            @_mute

        setCurrentPosition: (ms) ->
            @

        getCurrentPosition: ->
            0

        getLoadedPercent: ->
            0

        getTotalTime: ->
            0

    Events.mixTo(EngineCore)
    EngineCore
) ->
    if typeof exports is 'object'
        module.exports = factory()
    else if typeof define is 'function' and define.amd
        define([
            'muplayer/core/cfg'
            'muplayer/core/utils'
            'muplayer/lib/events'
        ], factory)
    else
        root._mu.EngineCore = factory(
            _mu.cfg
            _mu.utils
            _mu.Events
        )
