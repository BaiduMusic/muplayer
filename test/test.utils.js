var u = _mu.utils;

suite('utils', function() {
    test('#time2str()', function() {
        assert.equal(u.time2str(59), '00:59');
        assert.equal(u.time2str(59.6), '01:00');
        assert.equal(u.time2str(60), '01:00');
        assert.equal(u.time2str(75), '01:15');
        assert.equal(u.time2str(3675), '1:01:15');
    });

    test('#namespace()', function() {
        u.namespace('property.package');
        assert.deepEqual(_mu.property, {package: {}});
        u.namespace('property.package2');
        assert.deepEqual(_mu.property, {
            package: {},
            package2: {}
        });
    });

    test('#wrap()', function() {
        var hello = function(name) {
            return 'hello ' + name;
        }

        hello = u.wrap(hello, function(fn) {
            return 'before, ' + fn('moe') + ', after';
        });

        assert.equal(hello(), 'before, hello moe, after');
    });
});
