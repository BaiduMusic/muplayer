suite 'engine', ->
    setup ->
        p.off().reset().setVolume(0)

    test 'getEngineType可以获得当前内核的类型', ->
        t = p.getEngineType()
        assert.ok t in ['FlashMP3Core', 'FlashMP4Core', 'AudioCore']

    test '会自动switch到合适内核处理播放', (done) ->
        @timeout(4000)

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
