var p = new _mu.Player({
        mute: true,
        absoluteUrl: false,
        baseDir: '/st/dist',
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
    }),
    mp3 = '/st/mp3/rain.mp3',
    aac = '/st/mp3/coins.m4a';

suite('engine', function() {
    test('getEngineType可以获得当前内核的类型', function() {
        var t = p.getEngineType();
        assert.ok(t === 'FlashMP3Core' || t === 'FlashMP4Core' || t === 'AudioCore');
    });

    test('会自动switch到合适内核处理播放', function(done) {
        var t;
        p.on('playing', function() {
            t = p.getEngineType();
            if (p.getCur() === mp3) {
                assert.ok(t === 'FlashMP3Core' || t === 'AudioCore');
                p.setUrl(aac).play();
            } else if (p.getCur() === aac) {
                assert.ok(t === 'FlashMP4Core' || t === 'AudioCore');
                done();
            }
        });
        p.setUrl(mp3).play();
    });

    teardown(function() {
        p.off().reset();
    });
});
