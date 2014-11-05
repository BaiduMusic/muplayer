var p = new _mu.Player({
        mute: true,
        mode: 'list',
        absoluteUrl: false
    }),
    mp3 = '/st/mp3/rain.mp3';

window.muplayer = p;

suite('player', function() {
    suite('#play()', function() {
        test('播放开始后会派发playing事件', function(done) {
            p.on('playing', function() {
                assert.ok(true);
                done();
            });
            p.setUrl(mp3).play();
        });
    });

    suite('#pause()', function() {
        test('暂停播放后会派发pause事件', function(done) {
            p.on('playing', function() {
                p.pause();
            });
            p.on('pause', function() {
                assert.ok(true);
                done();
            });
            p.setUrl(mp3).play();
        });

        test('暂停后播放位置不会被重置', function(done) {
            p.on('timeupdate', function() {
                p.pause();
            });
            p.on('pause', function() {
                assert.ok(p.curPos() > 0);
                done();
            });
            p.setUrl(mp3).play();
        });
    });

    suite('#stop()', function() {
        test('停止后会派发suspend事件', function(done) {
            p.on('playing', function() {
                p.stop();
            });
            p.on('suspend', function() {
                assert.ok(true);
                done();
            });
            p.setUrl(mp3).play();
        });

        test('停止播放会将当前播放位置重置', function(done) {
            p.once('timeupdate', function() {
                p.stop();
            });
            p.on('suspend', function() {
                assert.equal(0, p.curPos());
                done();
            });
            p.setUrl(mp3).play();
        });
    });

    suite('#setCur()', function() {
        test('通过setCur设置sid后，可通过getCur取回该sid', function() {
            p.add([
                '1', '2', '3'
            ]).setCur('2');
            assert.equal('2', p.getCur());
        });

        test('重置播放列表后可以通过setCur设置到指定sid', function() {
            p.add([
                '1', '2', '3', '4', '5'
            ]).setCur('3');
            assert.equal('3', p.getCur());
            p.reset().add([
                '1', '2', '3', '4', '5'
            ]).setCur('3');
            assert.equal('3', p.getCur());
        });
    });

    teardown(function() {
        p.off().reset();
    });
});
