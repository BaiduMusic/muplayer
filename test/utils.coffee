u = _mu.utils

suite 'utils', ->
    test '#time2str()', ->
        assert.equal u.time2str(59), '00:59'
        assert.equal u.time2str(59.6), '01:00'
        assert.equal u.time2str(60), '01:00'
        assert.equal u.time2str(75), '01:15'
        assert.equal u.time2str(3675), '1:01:15'

    test '#namespace()', ->
        u.namespace('property.package')
        assert.deepEqual _mu.property, {package: {}}
        u.namespace('property.package2')
        assert.deepEqual(_mu.property, {
            package: {},
            package2: {}
        })

    test '#wrap()', ->
        hello = (name) ->
            "hello #{name}"

        hello = u.wrap(hello, (fn) ->
            "before, #{fn('moe')}, after"
        )

        assert.equal hello(), 'before, hello moe, after'

    test '#getExt()', ->
        assert.equal 'mp3', u.getExt('http://localhost:8123/?URLStr=http%3A%2F%2Fzhangmenshiting.baidu.com%2Fdata2%2Fmusic%2F124506768%2F124506768.mp3%3Fxcode%3Da6b8cd215f4f3affd3100a790a2a71bec3f47fcedb7fe8f9')
        assert.equal 'mp3', u.getExt('http://localhost:8123/test.mp3')
        assert.equal 'aac', u.getExt('http://localhost:8123/test.aac')
        assert.equal 'mp4', u.getExt('http://localhost:8123/test.mp4?Xode=XX')
        assert.equal '', u.getExt('http://localhost:8123/test')
