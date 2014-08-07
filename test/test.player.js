var p = new _mu.Player({
        mute: true,
        mode: 'list'
    }),
    mp3Path = '../src/doc/mp3/';

suite('player', function() {
    setup(function() {
        p.add([
            mp3Path + 'rain.mp3'
        ]);
    });

    suite('#play()', function() {
        test('should trigger playing event when play', function(done) {
            p.on('playing', function() {
                assert.ok(true);
                done();
            });
            p.play();
        });
    });

    teardown(function() {
        p.off().reset();
    });
});
