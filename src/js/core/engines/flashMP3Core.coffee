do (root = this, factory = (cfg, FlashCore) ->
    TYPES = cfg.engine.TYPES

    class FlashMP3Core extends FlashCore
        defaults:
            swf: '../dist/swf/muplayer_mp3.swf'
            instanceName: 'MP3Core'
            flashVer: '9.0.0'
        _supportedTypes: ['mp3']
        engineType: TYPES.FLASH_MP3

    FlashMP3Core
) ->
    if typeof exports is 'object'
        module.exports = factory()
    else if typeof define is 'function' and define.amd
        define([
            'muplayer/core/cfg'
            'muplayer/core/engines/flashCore'
        ], factory)
    else
        root._mu.FlashMP3Core = factory(
            _mu.cfg
            _mu.FlashCore
        )
