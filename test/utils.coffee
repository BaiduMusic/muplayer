u = _mu.utils
assert = chai.assert

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
