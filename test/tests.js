/*
# utils
*/


(function() {
  var mp3Path, p, u;

  u = _mu.utils;

  module('utils');

  test('isEmpty', function() {
    ok(u.isEmpty(null));
    ok(u.isEmpty());
    ok(u.isEmpty({}));
    ok(u.isEmpty([]));
    ok(u.isEmpty(false));
    return throws(u.isEmpty(1));
  });

  test('time2str', function() {
    equal(u.time2str(59), '00:59');
    equal(u.time2str(59.6), '01:00');
    equal(u.time2str(60), '01:00');
    equal(u.time2str(75), '01:15');
    return equal(u.time2str(3675), '1:01:15');
  });

  test('namespace', function() {
    u.namespace('property.package');
    deepEqual(_mu.property, {
      "package": {}
    });
    u.namespace('property.package2');
    return deepEqual(_mu.property, {
      "package": {},
      package2: {}
    });
  });

  test('wrap', function() {
    var hello;
    hello = function(name) {
      return "hello " + name;
    };
    hello = u.wrap(hello, function(fn) {
      return 'before, ' + fn('moe') + ', after';
    });
    return equal(hello(), 'before, hello moe, after');
  });

  /*
  # player
  */


  p = new _mu.Player;

  mp3Path = '/mp3/';

  module('player', {
    setup: function() {
      return p.add([mp3Path + '1.mp3', mp3Path + '2.mp3']);
    },
    teardown: function() {
      return p.off().reset();
    }
  });

  asyncTest('play', 1, function() {
    p.on('play', function() {
      ok(true);
      return start();
    });
    return p.play(true);
  });

}).call(this);
