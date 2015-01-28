suite 'playlist', ->
    setup ->
        p.off().reset().setVolume(0)

    suite '#add()', ->
        test '不能添加空的sid', ->
            p.add ''
            p.add []
            assert.deepEqual [], pl.list

        test '数字类型sid自动被转换成字符串', ->
            p.add 1
            assert.deepEqual ['1'], pl.list

        test '支持添加sids', ->
            p.add [1, '2', 3]
            assert.deepEqual ['1', '2', '3'], pl.list

        test '默认添加到playlist前面', ->
            p.add 1
            assert.deepEqual ['1'], pl.list
            p.add 2
            assert.deepEqual ['2', '1'], pl.list
            p.add ['3', '4']
            assert.deepEqual ['3', '4', '2', '1'], pl.list

        test '支持添加到playlist后面', ->
            p.add 1
            assert.deepEqual ['1'], pl.list
            p.add 2, false
            assert.deepEqual ['1', '2'], pl.list
            p.add ['3', '4'], false
            assert.deepEqual ['1', '2', '3', '4'], pl.list

        test '列表中不能添加重复的sid', ->
            p.add 1
            assert.deepEqual ['1'], pl.list
            p.add 1
            assert.deepEqual ['1'], pl.list
            p.add '1', false
            assert.deepEqual ['1'], pl.list

    suite '#remove()', ->
        test '可以从playlist移除指定sid或sids', ->
            p.add [1, 2, 3, 4, 5, 6]
            p.remove 2
            assert.deepEqual ['1', '3', '4', '5', '6'], pl.list
            p.remove [3, 4]
            assert.deepEqual ['1', '5', '6'], pl.list
            p.remove ['6', 7]
            assert.deepEqual ['1', '5'], pl.list

    suite '#getSongsNum()', ->
        test 'playre.getSongsNum()可以反映playlist中item总数', ->
            p.add [1, 2, 3]
            assert.equal 3, p.getSongsNum()
            p.add 4
            assert.equal 4, p.getSongsNum()
            p.remove [2, 3]
            assert.equal 2, p.getSongsNum()

    suite '#setMode() & getMode()', ->
        test '设置列表播放状态后可通过getMode取得状态', ->
            p.setMode 'loop'
            assert.equal 'loop', p.getMode()

        test '不能设置非法非法的列表状态', ->
            p.setMode 'list'
            assert.equal 'list', p.getMode()
            p.setMode 'test state'
            assert.equal 'list', p.getMode()

        test 'list模式下的上一首、下一首', ->
            p.setMode 'list'
            p.add ['a', 'b', 'c']
            assert.equal 'a', p.getCur()
            pl.next()
            assert.equal 'b', p.getCur()
            pl.next()
            assert.equal 'c', p.getCur()
            pl.prev()
            assert.equal 'b', p.getCur()
            pl.next()
            assert.equal 'c', p.getCur()
            assert.equal false, pl.next()

        test 'list模式下，列表播放完会派发事件', ->
            t = 0
            p.setMode 'list'
            p.add ['a']
            p.once 'player:next', (r) ->
                assert.equal 'a', r.cur
                assert.equal 1, ++t
                p.next()
            p.once 'player:next:fail', ->
                assert.equal 2, ++t
            p.next()

        test 'loop模式下的上一首、下一首', ->
            p.setMode 'loop'
            p.add ['a', 'b', 'c']
            assert.equal 'a', p.getCur()
            pl.prev()
            assert.equal 'c', p.getCur()
            pl.prev()
            assert.equal 'b', p.getCur()
            pl.next()
            assert.equal 'c', p.getCur()
            pl.next()
            assert.equal 'a', p.getCur()

        test 'single模式下单曲循环', ->
            p.setMode 'single'
            p.add ['a', 'b', 'c']
            assert.equal 'a', p.getCur()
            pl.next()
            assert.equal 'a', p.getCur()
            pl.prev()
            assert.equal 'a', p.getCur()

        # TODO: list-random模式需要仔细测一下
