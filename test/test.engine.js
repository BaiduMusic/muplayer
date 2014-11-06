var p = new _mu.Player({
        mute: true,
        volume: 0,
        absoluteUrl: false,
        baseDir: '/base/dist',
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
    mp3 = '/base/doc/mp3/rain.mp3',
    aac = '/base/doc/mp3/coins.mp4a',
    assert = chai.assert;

window.muplayer = p;

suite('engine', function() {
    setup(function() {
        p.setVolume(0);
    });

    test('getEngineType可以获得当前内核的类型', function() {
        var t = p.getEngineType();
        assert.ok(t === 'FlashMP3Core' || t === 'FlashMP4Core' || t === 'AudioCore');
    });

    test('会自动switch到合适内核处理播放', function(done) {
        this.timeout(4000);

        var t, url;

        p.on('playing', function() {
            t = p.getEngineType();
            url = p.getUrl();
            if (url === mp3) {
                assert.ok(t === 'FlashMP3Core' || t === 'AudioCore');
                p.setUrl(aac).play();
            } else if (url === aac) {
                assert.ok(t === 'FlashMP4Core' || t === 'AudioCore');
                done();
            }
        });
        p.setUrl(aac).play();
    });

    teardown(function() {
        p.off().reset();
    });
});
