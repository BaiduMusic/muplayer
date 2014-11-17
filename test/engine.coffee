p = new _mu.Player({
    mute: true
    volume: 0
    absoluteUrl: false
    baseDir: '/base/dist'
    engines: [
        {
            constructor: 'FlashMP3Core'
        },
        {
            constructor: 'FlashMP4Core'
        },
        {
            constructor: 'AudioCore'
        }
    ]
})
mp3 = '/base/doc/mp3/rain.mp3'
aac = '/base/doc/mp3/coins.mp4a'
assert = chai.assert

window.muplayer = p

suite 'engine', ->
    setup ->
        p.setVolume(0)

    test 'getEngineType可以获得当前内核的类型', ->
        t = p.getEngineType()
        assert.ok t in ['FlashMP3Core', 'FlashMP4Core', 'AudioCore']

    test '会自动switch到合适内核处理播放', (done) ->
        this.timeout(4000)

        p.on 'playing', ->
            t = p.getEngineType()
            url = p.getUrl()
            if url is mp3
                assert.ok t in ['FlashMP3Core', 'AudioCore']
                p.setUrl(aac).play()
            else if url is aac
                assert.ok t in ['FlashMP4Core', 'AudioCore']
                done()

        p.setUrl(mp3).play()

    teardown ->
        p.off().reset()
