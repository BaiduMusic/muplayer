##
# EngineCore是FlashCore, AudioCore等播放内核的基类
##
do (root = this, factory = (cfg, utils, Events) ->
    {EVENTS, STATES} = cfg.engine
    availableStates = (v for k, v of STATES)

    class EngineCore
        _supportedTypes: []

        getSupportedTypes: () ->
            @_supportedTypes

        canPlayType: (type) ->
            return $.inArray(type, @getSupportedTypes()) isnt -1

        reset: () ->
            @stop()
            @setUrl()
            @setState(STATES.READY)
            @

        play: () ->
            @

        pause: () ->
            @

        stop: () ->
            @

        setUrl: (url = '') ->
            @_url = url
            @

        getUrl: () ->
            @_url

        setState: (st) ->
            if st in availableStates and st isnt @_status
                @_status = st
                @trigger(EVENTS.STATECHANGE,
                    oldState: @_status
                    newState: st
                )

        getState: () ->
            @_status

        setVolume: (volume) ->
            @_volume = volume
            @

        getVolume: () ->
            @_volume

        setMute: (mute) ->
            @_mute = mute
            @

        getMute: () ->
            @_mute

        setCurrentPosition: (ms) ->
            @

        getCurrentPosition: () ->
            0

        getLoadedPercent: () ->
            0

        getTotalTime: () ->
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
