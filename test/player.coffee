suite 'player', ->
    setup ->
        p.setVolume(0)

    suite '#play()', ->
        test '播放开始后会派发playing事件', (done) ->
            p.on 'playing', ->
                assert.ok(true)
                done()
            p.setUrl(mp3).play()

        test '事件派发顺序', (done) ->
            this.timeout(3000)

            evts = []

            p.on 'player:statechange', (e) ->
                evts.push(e.newState)

            p.on 'ended', ->
                waitingIndex = $.inArray('waiting', evts)
                loadeddataIndex = $.inArray('loadeddata', evts)
                playingIndex = $.inArray('playing', evts)
                pauseIndex = $.inArray('pause', evts)
                endedIndex = $.inArray('ended', evts)

                assert.ok waitingIndex <= loadeddataIndex
                assert.ok loadeddataIndex < playingIndex
                assert.ok playingIndex < pauseIndex
                assert.ok pauseIndex < endedIndex

                done()

            p.setUrl(empty_mp3).play()

        test '播放后派发timeupdate', (done) ->
            t = 0

            p.on 'timeupdate', (pos) ->
                t++;
                if t is 1
                    lastPos = pos
                if t is 2
                    assert.ok pos isnt lastPos
                    p.pause()

            p.on 'pause', ->
                done()

            p.setUrl(empty_mp3).play()

    suite '#pause()', ->
        test '暂停播放后会派发pause事件', (done) ->
            p.on 'playing', ->
                p.pause()

            p.on 'pause', ->
                assert.ok true
                done()

            p.setUrl(mp3).play()

        test '暂停后播放位置不会被重置', (done) ->
            p.once 'timeupdate', ->
                p.pause()

            p.on 'pause', ->
                assert.ok p.curPos() > 0
                done()

            p.setUrl(mp3).play()

    suite '#stop()', ->
        test '停止后会派发suspend事件', (done) ->
            p.on 'playing', ->
                p.stop()

            p.on 'suspend', ->
                assert.ok true
                done()

            p.setUrl(mp3).play()

        test '停止播放会将当前播放位置重置', (done) ->
            p.once 'timeupdate', ->
                p.stop()

            p.on 'suspend', ->
                assert.equal 0, p.curPos()
                done()

            p.setUrl(mp3).play()

    suite '#replay()', ->
        test '重头播放', (done) ->
            p.once 'timeupdate', ->
                p.replay()
                p.once 'timeupdate', ->
                    assert.ok true
                    done()

            p.on 'suspend', ->
                assert.ok true

            p.setUrl(mp3).play()

    suite '#duration()', ->
        test 'rain.mp3的时长与时长格式化', (done) ->
            p.on 'timeupdate', ->
                assert.equal 8, ~~p.duration()
                assert.equal '00:08', p.duration(true)
                done()

            p.setUrl(mp3).play()

    suite '#getState()', ->
        test '播放、暂停和停止时可获得对应状态', (done) ->
            p.on 'playing', ->
                assert.equal 'playing', p.getState()
                p.pause()

            p.on 'pause', ->
                assert.equal 'pause', p.getState()
                p.stop()

            p.on 'suspend', ->
                assert.equal 'suspend', p.getState()
                done()

            p.setUrl(mp3).play()

    suite '#setUrl() & getUrl()', ->
        test '通过setUrl设置音频连接后，可通过getUrl取回', ->
            p.setUrl mp3
            assert.equal mp3, p.getUrl()

        test 'setUrl可以检测encode后的音频类型', ->
            p.on 'playing', ->
                assert.equal 'FlashMp3Core', p.getEngineType()

            assert.doesNotThrow ->
                p.setUrl(
                    'http://localhost:8123/?URLStr=http%3A%2F%2Fzhangmenshiting.baidu.com%2Fdata2%2Fmusic%2F124506768%2F124506768.mp3%3Fxcode%3Da6b8cd215f4f3affd3100a790a2a71bec3f47fcedb7fe8f9'
                ).play()

    suite '#setVolume() & getVolume()', ->
        test '通过setVolume设置的音量，可通过getVolume取回', ->
            p.setVolume 66
            assert.equal 66, p.getVolume()

        test '非法的音量取值不能设置成功', ->
            p.setVolume 85
            p.setVolume 101
            assert.equal 85, p.getVolume()
            p.setVolume -1
            assert.equal 85, p.getVolume()
            p.setVolume '35'
            assert.equal 35, p.getVolume()

        test '音量设置和是否静音相互独立', ->
            p.setMute false
            p.setVolume 0
            assert.equal false, p.getMute()
            p.setVolume 85
            p.setMute true
            assert.equal 85, p.getVolume()

    suite '#setMute() & getMute()', ->
        test '通过setMute设置的是否静音，通过getMute取得静音状态', ->
            p.setMute true
            assert.equal true, p.getMute()
            p.setMute false
            assert.equal false, p.getMute()

    suite '#setCur() & getCur()', ->
        test '通过setCur设置sid后，可通过getCur取回该sid', ->
            p.add([
                '1', '2', '3'
            ]).setCur('2')
            assert.equal '2', p.getCur()

        test '重置播放列表后可以通过setCur设置到指定sid', ->
            p.add([
                '1', '2', '3', '4', '5'
            ]).setCur('3')
            assert.equal '3', p.getCur()
            p.reset().add([
                '1', '2', '3', '4', '5'
            ]).setCur('3')
            assert.equal '3', p.getCur()

    teardown ->
        p.off().reset()
