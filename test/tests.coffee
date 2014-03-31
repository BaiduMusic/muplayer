###
# utils
###
u = _mu.utils

module 'utils'

test 'isEmpty', ->
    ok u.isEmpty(null)
    ok u.isEmpty()
    ok u.isEmpty({})
    ok u.isEmpty([])
    ok u.isEmpty(false)
    throws u.isEmpty(1)

test 'time2str', ->
    equal u.time2str(59), '00:59'
    equal u.time2str(59.6), '01:00'
    equal u.time2str(60), '01:00'
    equal u.time2str(75), '01:15'
    equal u.time2str(3675), '1:01:15'

test 'namespace', ->
    u.namespace('property.package')
    deepEqual(_mu.property, {package: {}})
    u.namespace('property.package2')
    deepEqual(_mu.property, {
        package: {},
        package2: {}
    })

test 'wrap', ->
    hello = (name) ->
        "hello #{name}"
    hello = u.wrap(hello, (fn) ->
        'before, ' + fn('moe') + ', after'
    )
    equal hello(), 'before, hello moe, after'

###
# player
###
p = new _mu.Player
mp3Path = '../dist/mp3/'

module 'player',
    setup: () ->
        p.add([
            mp3Path + 'rain.mp3'
            mp3Path + 'walking.mp3'
        ])
    teardown: () ->
        p.off().reset()

asyncTest 'play', 1, ->
    p.on 'play', () ->
        ok(true)
        start()
    p.play()
