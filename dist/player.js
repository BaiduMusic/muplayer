// @license
// Baidu Music Player: 0.9.2
// -------------------------
// (c) 2014 FE Team of Baidu Music
// Can be freely distributed under the BSD license.
(function(root, factory) {
  if (typeof root._mu === 'undefined') {
    root._mu = {};
  }
  if (typeof exports === 'object') {
    return module.exports = factory();
  } else if (typeof define === 'function' && define.amd) {
    return define('muplayer/core/cfg',factory);
  } else {
    return root._mu.cfg = factory();
  }
})(this, function() {
  var root;
  root = this;
  return $.extend({
    namespace: root._mu,
    debug: false,
    version: '0.9.2',
    timerResolution: 25,
    cdn: 'http://apps.bdimg.com/libs/muplayer/',
    engine: {
      TYPES: {
        FLASH_MP3: 'FlashMP3Core',
        FLASH_MP4: 'FlashMP4Core',
        AUDIO: 'AudioCore'
      },
      EVENTS: {
        STATECHANGE: 'engine:statechange',
        POSITIONCHANGE: 'engine:postionchange',
        PROGRESS: 'engine:progress',
        ERROR: 'engine:error',
        INIT: 'engine:init',
        INIT_FAIL: 'engine:init_fail'
      },
      STATES: {
        NOT_INIT: 'not_init',
        CANPLAYTHROUGH: 'canplaythrough',
        PREBUFFER: 'waiting',
        BUFFERING: 'loadeddata',
        PLAYING: 'playing',
        PAUSE: 'pause',
        STOP: 'suspend',
        END: 'ended'
      },
      ERRCODE: {
        MEDIA_ERR_ABORTED: '1',
        MEDIA_ERR_NETWORK: '2',
        MEDIA_ERR_DECODE: '3',
        MEDIA_ERR_SRC_NOT_SUPPORTED: '4'
      }
    }
  }, typeof root._mu === 'undefined' ? {} : root._mu.cfg);
});

(function(root, factory) {
  if (typeof exports === 'object') {
    return module.exports = factory();
  } else if (typeof define === 'function' && define.amd) {
    return define('muplayer/core/utils',['muplayer/core/cfg'], factory);
  } else {
    return root._mu.utils = factory(root._mu.cfg);
  }
})(this, function(cfg) {
  var ArrayProto, NumProto, ObjProto, StrProto, hasOwnProperty, name, push, toString, utils, _i, _len, _ref;
  utils = {};
  StrProto = String.prototype;
  NumProto = Number.prototype;
  ObjProto = Object.prototype;
  ArrayProto = Array.prototype;
  push = ArrayProto.push;
  hasOwnProperty = ObjProto.hasOwnProperty;
  toString = ObjProto.toString;
  _ref = ['Arguments', 'Function', 'String', 'Number', 'Date', 'RegExp'];
  for (_i = 0, _len = _ref.length; _i < _len; _i++) {
    name = _ref[_i];
    utils['is' + name] = (function(name) {
      return function(obj) {
        return toString.call(obj) === '[object ' + name + ']';
      };
    })(name);
  }
  if (!$.isFunction(StrProto.startsWith)) {
    StrProto.startsWith = function(str) {
      return this.slice(0, str.length) === str;
    };
  }
  if (!$.isFunction(StrProto.endsWith)) {
    StrProto.endsWith = function(str) {
      return this.slice(-str.length) === str;
    };
  }
  NumProto.toFixed = function(n) {
    var fixed, padding, pow;
    pow = Math.pow(10, n);
    fixed = (Math.round(this * pow) / pow).toString();
    if (n === 0) {
      return fixed;
    }
    if (fixed.indexOf('.') < 0) {
      fixed += '.';
    }
    padding = n + 1 - (fixed.length - fixed.indexOf('.'));
    while (padding--) {
      fixed += '0';
    }
    return fixed;
  };
  $.extend(utils, {
    isBoolean: function(obj) {
      return obj === true || obj === false || toString.call(obj) === '[object Boolean]';
    },
    has: function(obj, key) {
      return hasOwnProperty.call(obj, key);
    },
    random: function(min, max) {
      if (!max) {
        max = min;
        min = 0;
      }
      return min + Math.floor(Math.random() * (max - min + 1));
    },
    shuffle: function(list) {
      var i, item, rand, shuffled, _j, _len1;
      i = 0;
      shuffled = [];
      for (_j = 0, _len1 = list.length; _j < _len1; _j++) {
        item = list[_j];
        rand = this.random(i++);
        shuffled[i - 1] = shuffled[rand];
        shuffled[rand] = item;
      }
      return shuffled;
    },
    time2str: function(time) {
      var floor, hour, minute, pad, r, second;
      r = [];
      floor = Math.floor;
      time = Math.round(time);
      hour = floor(time / 3600);
      minute = floor((time - 3600 * hour) / 60);
      second = time % 60;
      pad = (function(_this) {
        return function(source, length) {
          var nagative, pre, str;
          pre = '';
          nagative = '';
          if (source < 0) {
            nagative = '-';
          }
          str = String(Math.abs(source));
          if (str.length < length) {
            pre = new Array(length - str.length + 1).join('0');
          }
          return nagative + pre + str;
        };
      })(this);
      if (hour) {
        r.push(hour);
      }
      r.push(pad(minute, 2));
      r.push(pad(second, 2));
      return r.join(':');
    },
    namespace: function() {
      var a, arg, d, i, l, o, period, _j, _len1, _ref1;
      a = arguments;
      period = '.';
      for (_j = 0, _len1 = a.length; _j < _len1; _j++) {
        arg = a[_j];
        o = cfg.namespace;
        if (arg.indexOf(period) > -1) {
          d = arg.split(period);
          _ref1 = [0, d.length], i = _ref1[0], l = _ref1[1];
          while (i < l) {
            o[d[i]] = o[d[i]] || {};
            o = o[d[i]];
            i++;
          }
        } else {
          o[arg] = o[arg] || {};
          o = o[arg];
        }
      }
      return o;
    },
    wrap: function(func, wrapper) {
      return function() {
        var args;
        args = [func];
        push.apply(args, arguments);
        return wrapper.apply(this, args);
      };
    },
    toAbsoluteUrl: function(url) {
      var div;
      div = document.createElement('div');
      div.innerHTML = '<a></a>';
      div.firstChild.href = url;
      div.innerHTML = div.innerHTML;
      return div.firstChild.href;
    }
  });
  return utils;
});

(function (root, factory) {
  if (typeof exports === 'object') {
    module.exports = factory();
  } else if (typeof define === 'function' && define.amd) {
    define('muplayer/lib/events',factory);
  } else {
    root._mu.Events = factory();
  }
})(this, function () {
  // Events
  // -----------------
  // Thanks to:
  //  - https://github.com/documentcloud/backbone/blob/master/backbone.js
  //  - https://github.com/joyent/node/blob/master/lib/events.js


  // Regular expression used to split event strings
  var eventSplitter = /\s+/


  // A module that can be mixed in to *any object* in order to provide it
  // with custom events. You may bind with `on` or remove with `off` callback
  // functions to an event; `trigger`-ing an event fires all callbacks in
  // succession.
  //
  //     var object = new Events();
  //     object.on('expand', function(){ alert('expanded'); });
  //     object.trigger('expand');
  //
  function Events() {
  }


  // Bind one or more space separated events, `events`, to a `callback`
  // function. Passing `"all"` will bind the callback to all events fired.
  Events.prototype.on = function(events, callback, context) {
    var cache, event, list
    if (!callback) return this

    cache = this.__events || (this.__events = {})
    events = events.split(eventSplitter)

    while (event = events.shift()) {
      list = cache[event] || (cache[event] = [])
      list.push(callback, context)
    }

    return this
  }

  Events.prototype.once = function(events, callback, context) {
    var that = this
    var cb = function() {
      that.off(events, cb)
      callback.apply(this, arguments)
    }
    this.on(events, cb, context)
  }

  // Remove one or many callbacks. If `context` is null, removes all callbacks
  // with that function. If `callback` is null, removes all callbacks for the
  // event. If `events` is null, removes all bound callbacks for all events.
  Events.prototype.off = function(events, callback, context) {
    var cache, event, list, i

    // No events, or removing *all* events.
    if (!(cache = this.__events)) return this
    if (!(events || callback || context)) {
      delete this.__events
      return this
    }

    events = events ? events.split(eventSplitter) : keys(cache)

    // Loop through the callback list, splicing where appropriate.
    while (event = events.shift()) {
      list = cache[event]
      if (!list) continue

      if (!(callback || context)) {
        delete cache[event]
        continue
      }

      for (i = list.length - 2; i >= 0; i -= 2) {
        if (!(callback && list[i] !== callback ||
            context && list[i + 1] !== context)) {
          list.splice(i, 2)
        }
      }
    }

    return this
  }


  // Trigger one or many events, firing all bound callbacks. Callbacks are
  // passed the same arguments as `trigger` is, apart from the event name
  // (unless you're listening on `"all"`, which will cause your callback to
  // receive the true name of the event as the first argument).
  Events.prototype.trigger = function(events) {
    var cache, event, all, list, i, len, rest = [], args, returned = true;
    if (!(cache = this.__events)) return this

    events = events.split(eventSplitter)

    // Fill up `rest` with the callback arguments.  Since we're only copying
    // the tail of `arguments`, a loop is much faster than Array#slice.
    for (i = 1, len = arguments.length; i < len; i++) {
      rest[i - 1] = arguments[i]
    }

    // For each event, walk through the list of callbacks twice, first to
    // trigger the event, then to trigger any `"all"` callbacks.
    while (event = events.shift()) {
      // Copy callback lists to prevent modification.
      if (all = cache.all) all = all.slice()
      if (list = cache[event]) list = list.slice()

      // Execute event callbacks.
      returned = triggerEvents(list, rest, this) && returned

      // Execute "all" callbacks.
      returned = triggerEvents(all, [event].concat(rest), this) && returned
    }

    return returned
  }

  Events.prototype.emit = Events.prototype.trigger

  // Mix `Events` to object instance or Class function.
  Events.mixTo = function(receiver) {
    receiver = isFunction(receiver) ? receiver.prototype : receiver
    var proto = Events.prototype

    for (var p in proto) {
      if (proto.hasOwnProperty(p)) {
        receiver[p] = proto[p]
      }
    }
  }


  // Helpers
  // -------

  var keys = Object.keys

  if (!keys) {
    keys = function(o) {
      var result = []

      for (var name in o) {
        if (o.hasOwnProperty(name)) {
          result.push(name)
        }
      }
      return result
    }
  }

  // Execute callbacks
  function triggerEvents(list, args, context) {
    if (list) {
      var i = 0, l = list.length, a1 = args[0], a2 = args[1], a3 = args[2], pass = true
      // call is faster than apply, optimize less than 3 argu
      // http://blog.csdn.net/zhengyinhui100/article/details/7837127
      switch (args.length) {
        case 0: for (; i < l; i += 2) {pass = list[i].call(list[i + 1] || context) !== false && pass} break;
        case 1: for (; i < l; i += 2) {pass = list[i].call(list[i + 1] || context, a1) !== false && pass} break;
        case 2: for (; i < l; i += 2) {pass = list[i].call(list[i + 1] || context, a1, a2) !== false && pass} break;
        case 3: for (; i < l; i += 2) {pass = list[i].call(list[i + 1] || context, a1, a2, a3) !== false && pass} break;
        default: for (; i < l; i += 2) {pass = list[i].apply(list[i + 1] || context, args) !== false && pass} break;
      }
    }
    // trigger will return false if one of the callbacks return false
    return pass;
  }

  function isFunction(func) {
    return Object.prototype.toString.call(func) === '[object Function]'
  }

  return Events
});

var __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

(function(root, factory) {
  if (typeof exports === 'object') {
    return module.exports = factory();
  } else if (typeof define === 'function' && define.amd) {
    return define('muplayer/core/playlist',['muplayer/core/utils', 'muplayer/lib/events'], factory);
  } else {
    return root._mu.Playlist = factory(_mu.utils, _mu.Events);
  }
})(this, function(utils, Events) {
  var Playlist;
  Playlist = (function() {
    function Playlist(options) {
      this.opts = $.extend({}, this.defaults, options);
      this.reset();
    }

    Playlist.prototype.reset = function() {
      this.cur = '';
      if ($.isArray(this.list)) {
        return this.list.length = 0;
      } else {
        return this.list = [];
      }
    };

    Playlist.prototype._resetListRandom = function(index) {
      var _i, _ref, _results;
      if (this.mode === 'list-random') {
        index = index || 0;
        this._listRandomIndex = index;
        this._listRandom = utils.shuffle((function() {
          _results = [];
          for (var _i = 0, _ref = this.list.length; 0 <= _ref ? _i < _ref : _i > _ref; 0 <= _ref ? _i++ : _i--){ _results.push(_i); }
          return _results;
        }).apply(this));
        return this.cur = this.list[this._listRandom[index]];
      }
    };

    Playlist.prototype._formatSid = function(sids) {
      var absoluteUrl, format, sid;
      absoluteUrl = this.opts.absoluteUrl;
      format = function(sid) {
        return absoluteUrl && utils.toAbsoluteUrl(sid) || '' + sid;
      };
      return $.isArray(sids) && ((function() {
        var _i, _len, _results;
        _results = [];
        for (_i = 0, _len = sids.length; _i < _len; _i++) {
          sid = sids[_i];
          if (sid) {
            _results.push(format(sid));
          }
        }
        return _results;
      })()) || format(sids);
    };

    Playlist.prototype.setMode = function(mode) {
      if (mode === 'single' || mode === 'random' || mode === 'list-random' || mode === 'list' || mode === 'loop') {
        this.mode = mode;
      }
      return this._resetListRandom();
    };

    Playlist.prototype.add = function(sid) {
      sid = this._formatSid(sid);
      this.remove(sid);
      if ($.isArray(sid) && sid.length) {
        this.list = sid.concat(this.list);
      } else if (sid) {
        this.list.unshift(sid);
      }
      this.trigger('playlist:add', sid);
      return this._resetListRandom();
    };

    Playlist.prototype.remove = function(sid) {
      var id, remove, _i, _len;
      remove = (function(_this) {
        return function(sid) {
          var i;
          i = $.inArray(sid, _this.list);
          if (i !== -1) {
            return _this.list.splice(i, 1);
          }
        };
      })(this);
      sid = this._formatSid(sid);
      if ($.isArray(sid)) {
        for (_i = 0, _len = sid.length; _i < _len; _i++) {
          id = sid[_i];
          remove(id);
        }
      } else {
        remove(sid);
      }
      this.trigger('playlist:remove', sid);
      return this._resetListRandom();
    };

    Playlist.prototype.prev = function() {
      var i, l, list, prev;
      list = this.list;
      i = $.inArray(this.cur, list);
      l = list.length;
      prev = i - 1;
      switch (this.mode) {
        case 'single':
          prev = i;
          break;
        case 'random':
          prev = utils.random(0, l - 1);
          break;
        case 'list':
          if (i = 0) {
            this.cur = list[0];
            return false;
          }
          break;
        case 'list-random':
          i = this._listRandomIndex--;
          prev = i - 1;
          if (i === 0) {
            prev = l - 1;
            this._resetListRandom(prev);
          }
          return this.cur = list[this._listRandom[prev]];
        case 'loop':
          if (i === 0) {
            prev = l - 1;
          }
      }
      return this.cur = list[prev];
    };

    Playlist.prototype.next = function() {
      var i, l, list, next;
      list = this.list;
      i = $.inArray(this.cur, list);
      l = list.length;
      next = i + 1;
      switch (this.mode) {
        case 'single':
          next = i;
          break;
        case 'random':
          next = utils.random(0, l - 1);
          break;
        case 'list':
          if (i === l - 1) {
            this.cur = list[0];
            return false;
          }
          break;
        case 'list-random':
          i = this._listRandomIndex++;
          next = i + 1;
          if (i === l - 1) {
            next = 0;
            this._resetListRandom(next);
          }
          return this.cur = list[this._listRandom[next]];
        case 'loop':
          if (i === l - 1) {
            next = 0;
          }
      }
      return this.cur = list[next];
    };

    Playlist.prototype.setCur = function(sid) {
      sid = sid + '';
      if (__indexOf.call(this.list, sid) < 0) {
        this.add(sid);
      }
      return this.cur = '' + sid;
    };

    return Playlist;

  })();
  Events.mixTo(Playlist);
  return Playlist;
});

var __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

(function(root, factory) {
  if (typeof exports === 'object') {
    return module.exports = factory();
  } else if (typeof define === 'function' && define.amd) {
    return define('muplayer/core/engines/engineCore',['muplayer/core/cfg', 'muplayer/core/utils', 'muplayer/lib/events'], factory);
  } else {
    return root._mu.EngineCore = factory(_mu.cfg, _mu.utils, _mu.Events);
  }
})(this, function(cfg, utils, Events) {
  var EVENTS, EngineCore, STATES, availableStates, k, v, _ref;
  _ref = cfg.engine, EVENTS = _ref.EVENTS, STATES = _ref.STATES;
  availableStates = (function() {
    var _results;
    _results = [];
    for (k in STATES) {
      v = STATES[k];
      _results.push(v);
    }
    return _results;
  })();
  EngineCore = (function() {
    function EngineCore() {}

    EngineCore.prototype._supportedTypes = [];

    EngineCore.prototype.getSupportedTypes = function() {
      return this._supportedTypes;
    };

    EngineCore.prototype.canPlayType = function(type) {
      return $.inArray(type, this.getSupportedTypes()) !== -1;
    };

    EngineCore.prototype.reset = function() {
      this.stop();
      this.setUrl();
      return this.setState(STATES.NOT_INIT);
    };

    EngineCore.prototype.play = function() {
      return this;
    };

    EngineCore.prototype.pause = function() {
      return this;
    };

    EngineCore.prototype.stop = function() {
      return this;
    };

    EngineCore.prototype.setUrl = function(url) {
      if (url == null) {
        url = '';
      }
      this._url = url;
      return this;
    };

    EngineCore.prototype.getUrl = function() {
      return this._url;
    };

    EngineCore.prototype.setState = function(st) {
      var oldState;
      if (__indexOf.call(availableStates, st) >= 0 && st !== this._state) {
        oldState = this._state;
        this._state = st;
        return this.trigger(EVENTS.STATECHANGE, {
          oldState: oldState,
          newState: st
        });
      }
    };

    EngineCore.prototype.getState = function() {
      return this._state;
    };

    EngineCore.prototype.setVolume = function(volume) {
      this._volume = volume;
      return this;
    };

    EngineCore.prototype.getVolume = function() {
      return this._volume;
    };

    EngineCore.prototype.setMute = function(mute) {
      this._mute = mute;
      return this;
    };

    EngineCore.prototype.getMute = function() {
      return this._mute;
    };

    EngineCore.prototype.setCurrentPosition = function(ms) {
      return this;
    };

    EngineCore.prototype.getCurrentPosition = function() {
      return 0;
    };

    EngineCore.prototype.getLoadedPercent = function() {
      return 0;
    };

    EngineCore.prototype.getTotalTime = function() {
      return 0;
    };

    return EngineCore;

  })();
  Events.mixTo(EngineCore);
  return EngineCore;
});

(function (root, factory) {
    if (typeof exports === 'object') {
        module.exports = factory();
    } else if (typeof define === 'function' && define.amd) {
        define('muplayer/lib/modernizr.audio',factory);
    } else {
        root._mu.Modernizr = factory();
    }
})(this, function () {
    // Modernizr 2.7.1 (Custom Build) | MIT & BSD
    // Build: http://modernizr.com/download/#-audio
    return (function( window, document, undefined ) {

        var version = '2.7.1',

        Modernizr = {},


        docElement = document.documentElement,

        mod = 'modernizr',
        modElem = document.createElement(mod),
        mStyle = modElem.style,

        inputElem  ,


        toString = {}.toString,    tests = {},
        inputs = {},
        attrs = {},

        classes = [],

        slice = classes.slice,

        featureName,



        _hasOwnProperty = ({}).hasOwnProperty, hasOwnProp;

        if ( !is(_hasOwnProperty, 'undefined') && !is(_hasOwnProperty.call, 'undefined') ) {
          hasOwnProp = function (object, property) {
            return _hasOwnProperty.call(object, property);
          };
        }
        else {
          hasOwnProp = function (object, property) {
            return ((property in object) && is(object.constructor.prototype[property], 'undefined'));
          };
        }


        if (!Function.prototype.bind) {
          Function.prototype.bind = function bind(that) {

            var target = this;

            if (typeof target != "function") {
                throw new TypeError();
            }

            var args = slice.call(arguments, 1),
                bound = function () {

                if (this instanceof bound) {

                  var F = function(){};
                  F.prototype = target.prototype;
                  var self = new F();

                  var result = target.apply(
                      self,
                      args.concat(slice.call(arguments))
                  );
                  if (Object(result) === result) {
                      return result;
                  }
                  return self;

                } else {

                  return target.apply(
                      that,
                      args.concat(slice.call(arguments))
                  );

                }

            };

            return bound;
          };
        }

        function setCss( str ) {
            mStyle.cssText = str;
        }

        function setCssAll( str1, str2 ) {
            return setCss(prefixes.join(str1 + ';') + ( str2 || '' ));
        }

        function is( obj, type ) {
            return typeof obj === type;
        }

        function contains( str, substr ) {
            return !!~('' + str).indexOf(substr);
        }


        function testDOMProps( props, obj, elem ) {
            for ( var i in props ) {
                var item = obj[props[i]];
                if ( item !== undefined) {

                                if (elem === false) return props[i];

                                if (is(item, 'function')){
                                    return item.bind(elem || obj);
                    }

                                return item;
                }
            }
            return false;
        }

        tests['audio'] = function() {
            var elem = document.createElement('audio'),
                bool = false;

            try {
                if ( bool = !!elem.canPlayType ) {
                    bool      = new Boolean(bool);
                    bool.ogg  = elem.canPlayType('audio/ogg; codecs="vorbis"').replace(/^no$/,'');
                    bool.mp3  = elem.canPlayType('audio/mpeg;')               .replace(/^no$/,'');

                                                        bool.wav  = elem.canPlayType('audio/wav; codecs="1"')     .replace(/^no$/,'');
                    bool.m4a  = ( elem.canPlayType('audio/x-m4a;')            ||
                                  elem.canPlayType('audio/aac;'))             .replace(/^no$/,'');
                }
            } catch(e) { }

            return bool;
        };    for ( var feature in tests ) {
            if ( hasOwnProp(tests, feature) ) {
                                        featureName  = feature.toLowerCase();
                Modernizr[featureName] = tests[feature]();

                classes.push((Modernizr[featureName] ? '' : 'no-') + featureName);
            }
        }



         Modernizr.addTest = function ( feature, test ) {
           if ( typeof feature == 'object' ) {
             for ( var key in feature ) {
               if ( hasOwnProp( feature, key ) ) {
                 Modernizr.addTest( key, feature[ key ] );
               }
             }
           } else {

             feature = feature.toLowerCase();

             if ( Modernizr[feature] !== undefined ) {
                                                  return Modernizr;
             }

             test = typeof test == 'function' ? test() : test;

             if (typeof enableClasses !== "undefined" && enableClasses) {
               docElement.className += ' ' + (test ? '' : 'no-') + feature;
             }
             Modernizr[feature] = test;

           }

           return Modernizr;
         };


        setCss('');
        modElem = inputElem = null;


        Modernizr._version      = version;


        return Modernizr;

    })(this, this.document);
});

var __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  __slice = [].slice;

(function(root, factory) {
  if (typeof exports === 'object') {
    return module.exports = factory();
  } else if (typeof define === 'function' && define.amd) {
    return define('muplayer/core/engines/audioCore',['muplayer/core/cfg', 'muplayer/core/utils', 'muplayer/core/engines/engineCore', 'muplayer/lib/modernizr.audio'], factory);
  } else {
    return root._mu.AudioCore = factory(_mu.cfg, _mu.utils, _mu.EngineCore, _mu.Modernizr);
  }
})(this, function(cfg, utils, EngineCore, Modernizr) {
  var AudioCore, ERRCODE, EVENTS, STATES, TYPES, win, _ref;
  win = window;
  _ref = cfg.engine, TYPES = _ref.TYPES, EVENTS = _ref.EVENTS, STATES = _ref.STATES, ERRCODE = _ref.ERRCODE;
  AudioCore = (function(_super) {
    __extends(AudioCore, _super);

    AudioCore.defaults = {
      confidence: 'maybe',
      preload: false,
      autoplay: false,
      needPlayEmpty: true,
      emptyMP3: 'empty.mp3'
    };

    AudioCore.prototype._supportedTypes = [];

    AudioCore.prototype.engineType = TYPES.AUDIO;

    function AudioCore(options) {
      var audio, k, least, levels, opts, playEmpty, v;
      this.opts = $.extend({}, AudioCore.defaults, options);
      this.opts.emptyMP3 = this.opts.baseDir + this.opts.emptyMP3;
      opts = this.opts;
      levels = {
        '': 0,
        maybe: 1,
        probably: 2
      };
      least = levels[opts.confidence];
      audio = Modernizr.audio;
      if (!audio) {
        return this;
      }
      for (k in audio) {
        v = audio[k];
        if (levels[v] >= least) {
          this._supportedTypes.push(k);
        }
      }
      audio = new Audio();
      audio.preload = opts.preload;
      audio.autoplay = opts.autoplay;
      audio.loop = false;
      audio.on = (function(_this) {
        return function(type, listener) {
          audio.addEventListener(type, listener, false);
          return audio;
        };
      })(this);
      audio.off = (function(_this) {
        return function(type, listener) {
          audio.removeEventListener(type, listener, false);
          return audio;
        };
      })(this);
      this.audio = audio;
      this._needCanPlay(['play', 'setCurrentPosition']);
      this.setState(STATES.NOT_INIT);
      this._initEvents();
      if (opts.needPlayEmpty) {
        playEmpty = (function(_this) {
          return function() {
            if (!_this.getUrl()) {
              _this.setUrl(opts.emptyMP3).play();
            }
            return win.removeEventListener('touchstart', playEmpty, false);
          };
        })(this);
        win.addEventListener('touchstart', playEmpty, false);
      }
    }

    AudioCore.prototype._test = function() {
      if (!Modernizr.audio || !this._supportedTypes.length) {
        return false;
      }
      return true;
    };

    AudioCore.prototype._initEvents = function() {
      var buffer, progressTimer, trigger;
      trigger = this.trigger;
      this.trigger = (function(_this) {
        return function(type, listener) {
          if (_this.getUrl() !== _this.opts.emptyMP3) {
            return trigger.call(_this, type, listener);
          }
        };
      })(this);
      buffer = (function(_this) {
        return function(per) {
          _this.setState(STATES.BUFFERING);
          return _this.trigger(EVENTS.PROGRESS, per || _this.getLoadedPercent());
        };
      })(this);
      progressTimer = null;
      return this.audio.on('loadstart', (function(_this) {
        return function() {
          var audio;
          audio = _this.audio;
          progressTimer = setInterval(function() {
            if (audio.readyState > 1) {
              return clearInterval(progressTimer);
            }
            return buffer();
          }, 50);
          return _this.setState(STATES.PREBUFFER);
        };
      })(this)).on('playing', (function(_this) {
        return function() {
          return _this.setState(STATES.PLAYING);
        };
      })(this)).on('pause', (function(_this) {
        return function() {
          return _this.setState(_this.getCurrentPosition() && STATES.PAUSE || STATES.STOP);
        };
      })(this)).on('ended', (function(_this) {
        return function() {
          return _this.setState(STATES.END);
        };
      })(this)).on('error', (function(_this) {
        return function() {
          _this.setState(STATES.END);
          return _this.trigger(EVENTS.ERROR, ERRCODE.MEDIA_ERR_NETWORK);
        };
      })(this)).on('waiting', (function(_this) {
        return function() {
          return _this.setState(_this.getCurrentPosition() && STATES.BUFFERING || STATES.PREBUFFER);
        };
      })(this)).on('timeupdate', (function(_this) {
        return function() {
          return _this.trigger(EVENTS.POSITIONCHANGE, _this.getCurrentPosition());
        };
      })(this)).on('progress', function(e) {
        var loaded, total;
        clearInterval(progressTimer);
        loaded = e.loaded || 0;
        total = e.total || 1;
        return buffer(loaded && (loaded / total).toFixed(2) * 1);
      });
    };

    AudioCore.prototype._needCanPlay = function(fnames) {
      var audio, name, _i, _len, _results;
      audio = this.audio;
      _results = [];
      for (_i = 0, _len = fnames.length; _i < _len; _i++) {
        name = fnames[_i];
        _results.push(this[name] = utils.wrap(this[name], (function(_this) {
          return function() {
            var args, fn, handle;
            fn = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
            if (audio.readyState < 3) {
              handle = function() {
                fn.apply(_this, args);
                return audio.off('canplay', handle);
              };
              audio.on('canplay', handle);
            } else {
              fn.apply(_this, args);
            }
            return _this;
          };
        })(this)));
      }
      return _results;
    };

    AudioCore.prototype.play = function() {
      this.audio.play();
      return this;
    };

    AudioCore.prototype.pause = function() {
      this.audio.pause();
      return this;
    };

    AudioCore.prototype.stop = function() {
      try {
        this.audio.currentTime = 0;
      } catch (_error) {

      } finally {
        this.pause();
      }
      return this;
    };

    AudioCore.prototype.setUrl = function(url) {
      if (url == null) {
        url = '';
      }
      this.audio.src = url;
      this.audio.load();
      return AudioCore.__super__.setUrl.call(this, url);
    };

    AudioCore.prototype.setVolume = function(volume) {
      this.audio.volume = volume / 100;
      return AudioCore.__super__.setVolume.call(this, volume);
    };

    AudioCore.prototype.setMute = function(mute) {
      this.audio.muted = mute;
      return AudioCore.__super__.setMute.call(this, mute);
    };

    AudioCore.prototype.setCurrentPosition = function(ms) {
      try {
        this.audio.currentTime = ms / 1000;
      } catch (_error) {

      } finally {
        this.play();
      }
      return this;
    };

    AudioCore.prototype.getCurrentPosition = function() {
      return this.audio.currentTime * 1000;
    };

    AudioCore.prototype.getLoadedPercent = function() {
      var be, duration;
      be = this.getBufferedEnd();
      duration = this.getTotalTime() / 1000;
      be = be > duration ? duration : be;
      return duration && (be / duration).toFixed(2) * 1 || 0;
    };

    AudioCore.prototype.getBufferedEnd = function() {
      var audio, be, bl, buffered, _ref1;
      audio = this.audio;
      buffered = audio.buffered;
      bl = buffered.length;
      be = 0;
      while (bl--) {
        if ((buffered.start(bl) <= (_ref1 = audio.currentTime) && _ref1 <= buffered.end(bl))) {
          be = buffered.end(bl);
          break;
        }
      }
      return be;
    };

    AudioCore.prototype.getTotalTime = function() {
      var duration;
      duration = this.audio.duration;
      if (isFinite(duration)) {
        return duration && duration * 1000 || 0;
      }
      return this.getBufferedEnd();
    };

    return AudioCore;

  })(EngineCore);
  return AudioCore;
});

// Timer.js: A periodic timer for Node.js and the browser.
//
// Copyright (c) 2012 Arthur Klepchukov, Jarvis Badgley, Florian Schäfer
// Licensed under the BSD license (BSD_LICENSE.txt)
//
// Version: 0.0.1
(function (root, factory) {
    if (typeof exports === 'object') {
        module.exports = factory();
    } else if (typeof define === 'function' && define.amd) {
        define('muplayer/lib/Timer',factory);
    } else {
        root._mu.Timer = factory();
    }
})(this, function () {
    function timeStringToMilliseconds(timeString) {
        if (typeof timeString === 'string') {

            if (isNaN(parseInt(timeString, 10))) {
                timeString = '1' + timeString;
            }

            var match = timeString
                .replace(/[^a-z0-9\.]/g, '')
                .match(/(?:(\d+(?:\.\d+)?)(?:days?|d))?(?:(\d+(?:\.\d+)?)(?:hours?|hrs?|h))?(?:(\d+(?:\.\d+)?)(?:minutes?|mins?|m\b))?(?:(\d+(?:\.\d+)?)(?:seconds?|secs?|s))?(?:(\d+(?:\.\d+)?)(?:milliseconds?|ms))?/);

            if (match[0]) {
                return parseFloat(match[1] || 0) * 86400000 +  // days
                       parseFloat(match[2] || 0) * 3600000 +   // hours
                       parseFloat(match[3] || 0) * 60000 +     // minutes
                       parseFloat(match[4] || 0) * 1000 +      // seconds
                       parseInt(match[5] || 0, 10);            // milliseconds
            }

            if (!isNaN(parseInt(timeString, 10))) {
                return parseInt(timeString, 10);
            }
        }

        if (typeof timeString === 'number') {
            return timeString;
        }

        return 0;
    }

    function millisecondsToTicks(milliseconds, resolution) {
        return parseInt(milliseconds / resolution, 10) || 1;
    }

    function Timer(resolution) {
        if (this instanceof Timer === false) {
            return new Timer(resolution);
        }

        this._notifications = [];
        this._resolution = timeStringToMilliseconds(resolution) || 1000;
        this._running = false;
        this._ticks = 0;
        this._timer = null;
        this._drift = 0;
    }

    Timer.prototype = {
        start: function () {
            var self = this;
            if (!this._running) {
                this._running = !this._running;
                setTimeout(function loopsyloop() {
                    self._ticks++;
                    for (var i = 0, l = self._notifications.length; i < l; i++) {
                        if (self._notifications[i] && self._ticks % self._notifications[i].ticks === 0) {
                            self._notifications[i].callback.call(self._notifications[i], { ticks: self._ticks, resolution: self._resolution });
                        }
                    }
                    if (self._running) {
                        self._timer = setTimeout(loopsyloop, self._resolution + self._drift);
                        self._drift = 0;
                    }
                }, this._resolution);
            }
            return this;
        },
        stop: function () {
            if (this._running) {
                this._running = !this._running;
                clearTimeout(this._timer);
            }
            return this;
        },
        reset: function () {
            this.stop();
            this._ticks = 0;
            return this;
        },
        clear: function () {
            this.reset();
            this._notifications = [];
            return this;
        },
        ticks: function () {
            return this._ticks;
        },
        resolution: function () {
            return this._resolution;
        },
        running: function () {
            return this._running;
        },
        bind: function (when, callback) {
            if (when && callback) {
                var ticks = millisecondsToTicks(timeStringToMilliseconds(when), this._resolution);
                this._notifications.push({
                    ticks: ticks,
                    callback: callback
                });
            }
            return this;
        },
        unbind: function (callback) {
            if (!callback) {
                this._notifications = [];
            } else {
                for (var i = 0, l = this._notifications.length; i < l; i++) {
                    if (this._notifications[i] && this._notifications[i].callback === callback) {
                        this._notifications.splice(i, 1);
                    }
                }
            }
            return this;
        },
        drift: function (timeDrift) {
            this._drift = timeDrift;
            return this;
        }
    };

    Timer.prototype.every = Timer.prototype.bind;
    Timer.prototype.after = function (when, callback) {
        var self = this;
        Timer.prototype.bind.call(self, when, function fn () {
            Timer.prototype.unbind.call(self, fn);
            callback.apply(this, arguments);
        });
        return this;
    };

    return Timer;
});

(function (root, factory) {
    if (typeof exports === 'object') {
        module.exports = factory();
    } else if (typeof define === 'function' && define.amd) {
        define('muplayer/lib/jquery.swfobject',factory);
    } else {
        factory();
    }
})(this, function () {
    // jQuery SWFObject v1.1.1 MIT/GPL @jon_neal
    // http://jquery.thewikies.com/swfobject
    (function($, flash, Plugin) {
        var OBJECT = 'object',
            ENCODE = true;

        function _compareArrayIntegers(a, b) {
            var x = (a[0] || 0) - (b[0] || 0);

            return x > 0 || (
                !x &&
                a.length > 0 &&
                _compareArrayIntegers(a.slice(1), b.slice(1))
            );
        }

        function _objectToArguments(obj) {
            if (typeof obj != OBJECT) {
                return obj;
            }

            var arr = [],
                str = '';

            for (var i in obj) {
                if (typeof obj[i] == OBJECT) {
                    str = _objectToArguments(obj[i]);
                }
                else {
                    str = [i, (ENCODE) ? encodeURI(obj[i]) : obj[i]].join('=');
                }

                arr.push(str);
            }

            return arr.join('&');
        }

        function _objectFromObject(obj) {
            var arr = [];

            for (var i in obj) {
                if (obj[i]) {
                    arr.push([i, '="', obj[i], '"'].join(''));
                }
            }

            return arr.join(' ');
        }

        function _paramsFromObject(obj) {
            var arr = [];

            for (var i in obj) {
                arr.push([
                    '<param name="', i,
                    '" value="', _objectToArguments(obj[i]), '" />'
                ].join(''));
            }

            return arr.join('');
        }

        try {
            var flashVersion = Plugin.description || (function () {
                return (
                    new Plugin('ShockwaveFlash.ShockwaveFlash')
                ).GetVariable('$version');
            }())
        }
        catch (e) {
            flashVersion = 'Unavailable';
        }

        var flashVersionMatchVersionNumbers = flashVersion.match(/\d+/g) || [0];

        $[flash] = {
            available: flashVersionMatchVersionNumbers[0] > 0,

            activeX: Plugin && !Plugin.name,

            version: {
                original: flashVersion,
                array: flashVersionMatchVersionNumbers,
                string: flashVersionMatchVersionNumbers.join('.'),
                major: parseInt(flashVersionMatchVersionNumbers[0], 10) || 0,
                minor: parseInt(flashVersionMatchVersionNumbers[1], 10) || 0,
                release: parseInt(flashVersionMatchVersionNumbers[2], 10) || 0
            },

            hasVersion: function (version) {
                var versionArray = (/string|number/.test(typeof version))
                    ? version.toString().split('.')
                    : (/object/.test(typeof version))
                        ? [version.major, version.minor]
                        : version || [0, 0];

                return _compareArrayIntegers(
                    flashVersionMatchVersionNumbers,
                    versionArray
                );
            },

            encodeParams: true,

            expressInstall: 'expressInstall.swf',
            expressInstallIsActive: false,

            create: function (obj) {
                var instance = this;

                if (
                    !obj.swf ||
                    instance.expressInstallIsActive ||
                    (!instance.available && !obj.hasVersionFail)
                ) {
                    return false;
                }

                if (!instance.hasVersion(obj.hasVersion || 1)) {
                    instance.expressInstallIsActive = true;

                    if (typeof obj.hasVersionFail == 'function') {
                        if (!obj.hasVersionFail.apply(obj)) {
                            return false;
                        }
                    }

                    obj = {
                        swf: obj.expressInstall || instance.expressInstall,
                        height: 137,
                        width: 214,
                        flashvars: {
                            MMredirectURL: location.href,
                            MMplayerType: (instance.activeX)
                                ? 'ActiveX' : 'PlugIn',
                            MMdoctitle: document.title.slice(0, 47) +
                                ' - Flash Player Installation'
                        }
                    };
                }

                attrs = {
                    data: obj.swf,
                    type: 'application/x-shockwave-flash',
                    id: obj.id || 'flash_' + Math.floor(Math.random() * 999999999),
                    width: obj.width || 320,
                    height: obj.height || 180,
                    style: obj.style || ''
                };

                ENCODE = typeof obj.useEncode !== 'undefined' ? obj.useEncode : instance.encodeParams;

                obj.movie = obj.swf;
                obj.wmode = obj.wmode || 'opaque';

                delete obj.fallback;
                delete obj.hasVersion;
                delete obj.hasVersionFail;
                delete obj.height;
                delete obj.id;
                delete obj.swf;
                delete obj.useEncode;
                delete obj.width;

                var flashContainer = document.createElement('div');

                flashContainer.innerHTML = [
                    '<object ', _objectFromObject(attrs), '>',
                    _paramsFromObject(obj),
                    '</object>'
                ].join('');

                return flashContainer.firstChild;
            }
        };

        $.fn[flash] = function (options) {
            var $this = this.find(OBJECT).andSelf().filter(OBJECT);

            if (/string|object/.test(typeof options)) {
                this.each(
                    function () {
                        var $this = $(this),
                            flashObject;

                        options = (typeof options == OBJECT) ? options : {
                            swf: options
                        };

                        options.fallback = this;

                        flashObject = $[flash].create(options);

                        if (flashObject) {
                            $this.children().remove();

                            $this.html(flashObject);
                        }
                    }
                );
            }

            if (typeof options == 'function') {
                $this.each(
                    function () {
                        var instance = this,
                        jsInteractionTimeoutMs = 'jsInteractionTimeoutMs';

                        instance[jsInteractionTimeoutMs] =
                            instance[jsInteractionTimeoutMs] || 0;

                        if (instance[jsInteractionTimeoutMs] < 660) {
                            if (instance.clientWidth || instance.clientHeight) {
                                options.call(instance);
                            }
                            else {
                                setTimeout(
                                    function () {
                                        $(instance)[flash](options);
                                    },
                                    instance[jsInteractionTimeoutMs] + 66
                                );
                            }
                        }
                    }
                );
            }

            return $this;
        };
    }(
        jQuery,
        'flash',
        navigator.plugins['Shockwave Flash'] || window.ActiveXObject
    ));
});

var __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  __slice = [].slice;

(function(root, factory) {
  if (typeof exports === 'object') {
    return module.exports = factory();
  } else if (typeof define === 'function' && define.amd) {
    return define('muplayer/core/engines/flashCore',['muplayer/core/cfg', 'muplayer/core/utils', 'muplayer/lib/Timer', 'muplayer/core/engines/engineCore', 'muplayer/lib/jquery.swfobject'], factory);
  } else {
    return root._mu.FlashCore = factory(_mu.cfg, _mu.utils, _mu.Timer, _mu.EngineCore);
  }
})(this, function(cfg, utils, Timer, EngineCore) {
  var ERRCODE, EVENTS, FlashCore, STATES, STATESCODE, timerResolution, _ref;
  _ref = cfg.engine, EVENTS = _ref.EVENTS, STATES = _ref.STATES, ERRCODE = _ref.ERRCODE;
  timerResolution = cfg.timerResolution;
  STATESCODE = {
    '-1': STATES.NOT_INIT,
    '1': STATES.CANPLAYTHROUGH,
    '2': STATES.PREBUFFER,
    '3': STATES.BUFFERING,
    '4': STATES.PLAYING,
    '5': STATES.PAUSE,
    '6': STATES.STOP,
    '7': STATES.END
  };
  FlashCore = (function(_super) {
    __extends(FlashCore, _super);

    FlashCore.defaults = {
      expressInstaller: 'expressInstall.swf'
    };

    function FlashCore(options) {
      var baseDir, id, instanceName, opts;
      this.opts = opts = $.extend({}, FlashCore.defaults, this.defaults, options);
      this._state = STATES.NOT_INIT;
      this._loaded = false;
      this._queue = [];
      this._needFlashReady(['play', 'pause', 'stop', 'setCurrentPosition', '_setUrl', '_setVolume', '_setMute']);
      this._unexceptionGet(['getCurrentPosition', 'getLoadedPercent', 'getTotalTime']);
      baseDir = opts.baseDir;
      id = 'muplayer_' + setTimeout((function() {}), 0);
      instanceName = opts.instanceName + '_' + id;
      utils.namespace('engines')[instanceName] = this;
      instanceName = '_mu.engines.' + instanceName;
      this.flash = $.flash.create({
        swf: baseDir + opts.swf,
        id: id,
        height: 1,
        width: 1,
        allowscriptaccess: 'always',
        wmode: 'transparent',
        expressInstaller: baseDir + opts.expressInstaller,
        flashvars: {
          _instanceName: instanceName,
          _buffertime: 5000
        }
      });
      opts.$el.append(this.flash);
      this._initEvents();
    }

    FlashCore.prototype._test = function() {
      var opts;
      opts = this.opts;
      if (!this.flash || !$.flash.hasVersion(opts.flashVer)) {
        return false;
      }
      return true;
    };

    FlashCore.prototype._initEvents = function() {
      var triggerPosition, triggerProgress;
      this.progressTimer = new Timer(timerResolution);
      this.positionTimer = new Timer(timerResolution);
      triggerProgress = (function(_this) {
        return function() {
          var per;
          per = _this.getLoadedPercent();
          if (_this._lastPer !== per) {
            _this._lastPer = per;
            _this.trigger(EVENTS.PROGRESS, per);
          }
          if (per === 1) {
            return _this.progressTimer.stop();
          }
        };
      })(this);
      triggerPosition = (function(_this) {
        return function() {
          var pos;
          pos = _this.getCurrentPosition();
          if (_this._lastPos !== pos) {
            _this._lastPos = pos;
            return _this.trigger(EVENTS.POSITIONCHANGE, pos);
          }
        };
      })(this);
      this.progressTimer.every('100 ms', triggerProgress);
      this.positionTimer.every('100 ms', triggerPosition);
      return this.on(EVENTS.STATECHANGE, (function(_this) {
        return function(e) {
          var st;
          st = e.newState;
          switch (st) {
            case STATES.PREBUFFER:
            case STATES.PLAYING:
              _this.progressTimer.start();
              break;
            case STATES.PAUSE:
            case STATES.STOP:
              _this.progressTimer.stop();
              break;
            case STATES.END:
              _this.progressTimer.reset();
          }
          switch (st) {
            case STATES.PLAYING:
              return _this.positionTimer.start();
            case STATES.PAUSE:
            case STATES.STOP:
              _this.positionTimer.stop();
              return triggerPosition();
            case STATES.END:
              return _this.positionTimer.reset();
          }
        };
      })(this));
    };

    FlashCore.prototype._needFlashReady = function(fnames) {
      var name, _i, _len, _results;
      _results = [];
      for (_i = 0, _len = fnames.length; _i < _len; _i++) {
        name = fnames[_i];
        _results.push(this[name] = utils.wrap(this[name], (function(_this) {
          return function() {
            var args, fn;
            fn = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
            if (_this._loaded) {
              fn.apply(_this, args);
            } else {
              _this._pushQueue(fn, args);
            }
            return _this;
          };
        })(this)));
      }
      return _results;
    };

    FlashCore.prototype._unexceptionGet = function(fnames) {
      var name, _i, _len, _results;
      _results = [];
      for (_i = 0, _len = fnames.length; _i < _len; _i++) {
        name = fnames[_i];
        _results.push(this[name] = utils.wrap(this[name], (function(_this) {
          return function() {
            var args, fn;
            fn = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
            try {
              return fn.apply(_this, args);
            } catch (_error) {
              return 0;
            }
          };
        })(this)));
      }
      return _results;
    };

    FlashCore.prototype._pushQueue = function(fn, args) {
      return this._queue.push([fn, args]);
    };

    FlashCore.prototype._fireQueue = function() {
      var args, fn, _ref1, _results;
      _results = [];
      while (this._queue.length) {
        _ref1 = this._queue.shift(), fn = _ref1[0], args = _ref1[1];
        _results.push(fn.apply(this, args));
      }
      return _results;
    };

    FlashCore.prototype.play = function() {
      this.flash.f_play();
      return this;
    };

    FlashCore.prototype.pause = function() {
      this.flash.f_pause();
      return this;
    };

    FlashCore.prototype.stop = function() {
      this.flash.f_stop();
      return this;
    };

    FlashCore.prototype._setUrl = function(url) {
      return this.flash.f_load(url);
    };

    FlashCore.prototype.setUrl = function(url) {
      if (url) {
        this._setUrl(url);
        (function(_this) {
          return (function() {
            var check, checker;
            checker = null;
            check = function(e) {
              if (e.newState === STATES.PLAYING && e.oldState === STATES.PREBUFFER) {
                return checker = setTimeout(function() {
                  _this.off(EVENTS.STATECHANGE, check);
                  if (_this.getCurrentPosition() < 100) {
                    _this.setState(STATES.END);
                    return _this.trigger(EVENTS.ERROR, ERRCODE.MEDIA_ERR_SRC_NOT_SUPPORTED);
                  }
                }, 2000);
              } else {
                return clearTimeout(checker);
              }
            };
            return _this.off(EVENTS.STATECHANGE, check).on(EVENTS.STATECHANGE, check);
          });
        })(this)();
      }
      return FlashCore.__super__.setUrl.call(this, url);
    };

    FlashCore.prototype.getState = function(code) {
      return STATESCODE[code] || this._state;
    };

    FlashCore.prototype._setVolume = function(volume) {
      return this.flash.setData('volume', volume);
    };

    FlashCore.prototype.setVolume = function(volume) {
      this._setVolume(volume);
      return FlashCore.__super__.setVolume.call(this, volume);
    };

    FlashCore.prototype._setMute = function(mute) {
      return this.flash.setData('mute', mute);
    };

    FlashCore.prototype.setMute = function(mute) {
      this._setMute(mute);
      return FlashCore.__super__.setMute.call(this, mute);
    };

    FlashCore.prototype.setCurrentPosition = function(ms) {
      this.flash.f_play(ms);
      return this;
    };

    FlashCore.prototype.getCurrentPosition = function() {
      return this.flash.getData('position');
    };

    FlashCore.prototype.getLoadedPercent = function() {
      return this.flash.getData('loadedPct');
    };

    FlashCore.prototype.getTotalTime = function() {
      return this.flash.getData('length');
    };

    FlashCore.prototype._swfOnLoad = function() {
      this._loaded = true;
      return setTimeout((function(_this) {
        return function() {
          return _this._fireQueue();
        };
      })(this), 0);
    };

    FlashCore.prototype._swfOnStateChange = function(code) {
      return this.setState(this.getState(code));
    };

    FlashCore.prototype._swfOnErr = function(e) {
      this.setState(STATES.END);
      this.trigger(EVENTS.ERROR);
      return typeof console !== "undefined" && console !== null ? console.error(e) : void 0;
    };

    return FlashCore;

  })(EngineCore);
  return FlashCore;
});

var __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

(function(root, factory) {
  if (typeof exports === 'object') {
    return module.exports = factory();
  } else if (typeof define === 'function' && define.amd) {
    return define('muplayer/core/engines/flashMP3Core',['muplayer/core/cfg', 'muplayer/core/engines/flashCore'], factory);
  } else {
    return root._mu.FlashMP3Core = factory(_mu.cfg, _mu.FlashCore);
  }
})(this, function(cfg, FlashCore) {
  var FlashMP3Core, TYPES;
  TYPES = cfg.engine.TYPES;
  FlashMP3Core = (function(_super) {
    __extends(FlashMP3Core, _super);

    function FlashMP3Core() {
      return FlashMP3Core.__super__.constructor.apply(this, arguments);
    }

    FlashMP3Core.prototype.defaults = {
      swf: 'muplayer_mp3.swf',
      instanceName: 'MP3Core',
      flashVer: '9.0.0'
    };

    FlashMP3Core.prototype._supportedTypes = ['mp3'];

    FlashMP3Core.prototype.engineType = TYPES.FLASH_MP3;

    return FlashMP3Core;

  })(FlashCore);
  return FlashMP3Core;
});

var __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

(function(root, factory) {
  if (typeof exports === 'object') {
    return module.exports = factory();
  } else if (typeof define === 'function' && define.amd) {
    return define('muplayer/core/engines/flashMP4Core',['muplayer/core/cfg', 'muplayer/core/engines/flashCore'], factory);
  } else {
    return root._mu.FlashMP4Core = factory(_mu.cfg, _mu.FlashCore);
  }
})(this, function(cfg, FlashCore) {
  var FlashMP4Core, TYPES;
  TYPES = cfg.engine.TYPES;
  FlashMP4Core = (function(_super) {
    __extends(FlashMP4Core, _super);

    function FlashMP4Core() {
      return FlashMP4Core.__super__.constructor.apply(this, arguments);
    }

    FlashMP4Core.prototype.defaults = {
      swf: 'muplayer_mp4.swf',
      instanceName: 'MP4Core',
      flashVer: '9.0.115'
    };

    FlashMP4Core.prototype._supportedTypes = ['m4a'];

    FlashMP4Core.prototype.engineType = TYPES.FLASH_MP4;

    return FlashMP4Core;

  })(FlashCore);
  return FlashMP4Core;
});

(function(root, factory) {
  if (typeof exports === 'object') {
    return module.exports = factory();
  } else if (typeof define === 'function' && define.amd) {
    return define('muplayer/core/engines/engine',[
            'muplayer/core/cfg'
            , 'muplayer/core/utils'
            , 'muplayer/lib/events'
            , 'muplayer/core/engines/engineCore'
            , 'muplayer/core/engines/audioCore'
                        , 'muplayer/core/engines/flashMP3Core'
            , 'muplayer/core/engines/flashMP4Core'
                    ], factory);
  } else {
    return root._mu.Engine = factory(
            _mu.cfg
            , _mu.utils
            , _mu.Events
            , _mu.EngineCore
            , _mu.AudioCore
                        , _mu.FlashMP3Core
            , _mu.FlashMP4Core
                    );
  }
})(this, function(cfg, utils, Events, EngineCore, AudioCore, FlashMP3Core, FlashMP4Core) {
  var EVENTS, Engine, STATES, extReg, timerResolution, _ref;
  _ref = cfg.engine, EVENTS = _ref.EVENTS, STATES = _ref.STATES;
  timerResolution = cfg.timerResolution;
  extReg = /\.(\w+)(\?.*)?$/;
  Engine = (function() {
    Engine.el = '<div id="muplayer_container_{{DATETIME}}" style="width: 1px; height: 1px; overflow: hidden"></div>';

    Engine.prototype.defaults = {
      engines: [
                                {
                    constructor: FlashMP3Core
                },
                {
                    constructor: FlashMP4Core
                },
                                {
                    constructor: AudioCore
                }
            ]
    };

    function Engine(options) {
      this.opts = $.extend({}, this.defaults, options);
      this._initEngines();
    }

    Engine.prototype._initEngines = function() {
      var $el, args, constructor, engine, i, opts, _i, _len, _ref1;
      this.engines = [];
      opts = this.opts;
      $el = $(Engine.el.replace(/{{DATETIME}}/g, +new Date())).appendTo('body');
      _ref1 = opts.engines;
      for (i = _i = 0, _len = _ref1.length; _i < _len; i = ++_i) {
        engine = _ref1[i];
        constructor = engine.constructor;
        args = engine.args || {};
        args.baseDir = opts.baseDir;
        args.$el = $el;
        try {
          if (!$.isFunction(constructor)) {
            constructor = eval(constructor);
          }
          engine = new constructor(args);
        } catch (_error) {
          throw "Missing constructor: " + (String(engine.constructor));
        }
        if (engine._test()) {
          this.engines.push(engine);
        }
      }
      if (this.engines.length) {
        return this.setEngine(this.engines[0]);
      } else {
        return this.setEngine(new EngineCore);
      }
    };

    Engine.prototype.setEngine = function(engine) {
      var bindEvents, errorHandle, oldEngine, positionHandle, progressHandle, statechangeHandle, unbindEvents;
      this._lastE = {};
      statechangeHandle = (function(_this) {
        return function(e) {
          if (e.oldState === _this._lastE.oldState && e.newState === _this._lastE.newState) {
            return;
          }
          _this._lastE = {
            oldState: e.oldState,
            newState: e.newState
          };
          return _this.trigger(EVENTS.STATECHANGE, e);
        };
      })(this);
      positionHandle = (function(_this) {
        return function(pos) {
          return _this.trigger(EVENTS.POSITIONCHANGE, pos);
        };
      })(this);
      progressHandle = (function(_this) {
        return function(progress) {
          return _this.trigger(EVENTS.PROGRESS, progress);
        };
      })(this);
      errorHandle = (function(_this) {
        return function(e) {
          return _this.trigger(EVENTS.ERROR, e);
        };
      })(this);
      bindEvents = function(engine) {
        return engine.on(EVENTS.STATECHANGE, statechangeHandle).on(EVENTS.POSITIONCHANGE, positionHandle).on(EVENTS.PROGRESS, progressHandle).on(EVENTS.ERROR, errorHandle);
      };
      unbindEvents = function(engine) {
        return engine.off(EVENTS.STATECHANGE, statechangeHandle).off(EVENTS.POSITIONCHANGE, positionHandle).off(EVENTS.PROGRESS, progressHandle).on(EVENTS.ERROR, errorHandle);
      };
      if (!this.curEngine) {
        return this.curEngine = bindEvents(engine);
      } else if (this.curEngine !== engine) {
        oldEngine = this.curEngine;
        unbindEvents(oldEngine).reset();
        this.curEngine = bindEvents(engine);
        return this.curEngine.setVolume(oldEngine.getVolume()).setMute(oldEngine.getMute());
      }
    };

    Engine.prototype.canPlayType = function(type) {
      return $.inArray(type, this.getSupportedTypes()) !== -1;
    };

    Engine.prototype.getSupportedTypes = function() {
      var engine, types, _i, _len, _ref1;
      types = [];
      _ref1 = this.engines;
      for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
        engine = _ref1[_i];
        types = types.concat(engine.getSupportedTypes());
      }
      return types;
    };

    Engine.prototype.switchEngineByType = function(type) {
      var engine, match, _i, _len, _ref1;
      match = false;
      _ref1 = this.engines;
      for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
        engine = _ref1[_i];
        if (engine.canPlayType(type)) {
          this.setEngine(engine);
          match = true;
          break;
        }
      }
      if (!match) {
        return this.setEngine(this.engines[0]);
      }
    };

    Engine.prototype.reset = function() {
      this.curEngine.reset();
      return this;
    };

    Engine.prototype.setUrl = function(url) {
      var ext;
      if (extReg.test(url)) {
        ext = RegExp.$1.toLocaleLowerCase();
      }
      if (this.canPlayType(ext)) {
        if (!this.curEngine.canPlayType(ext)) {
          this.switchEngineByType(ext);
        }
      } else {
        throw "Can not play with: " + ext;
      }
      this.curEngine.setUrl(url);
      return this;
    };

    Engine.prototype.getUrl = function() {
      return this.curEngine.getUrl();
    };

    Engine.prototype.play = function() {
      this.curEngine.play();
      return this;
    };

    Engine.prototype.pause = function() {
      this.curEngine.pause();
      this.setState(STATES.PAUSE);
      return this;
    };

    Engine.prototype.stop = function() {
      this.curEngine.stop();
      this.setState(STATES.STOP);
      return this;
    };

    Engine.prototype.setState = function(st) {
      this.curEngine.setState(st);
      return this;
    };

    Engine.prototype.getState = function() {
      return this.curEngine.getState();
    };

    Engine.prototype.setMute = function(mute) {
      this.curEngine.setMute(!!mute);
      return this;
    };

    Engine.prototype.getMute = function() {
      return this.curEngine.getMute();
    };

    Engine.prototype.setVolume = function(volume) {
      if ($.isNumeric(volume) && volume >= 0 && volume <= 100) {
        this.curEngine.setVolume(volume);
      }
      return this;
    };

    Engine.prototype.getVolume = function() {
      return this.curEngine.getVolume();
    };

    Engine.prototype.setCurrentPosition = function(ms) {
      ms = ~~ms;
      this.curEngine.setCurrentPosition(ms);
      return this;
    };

    Engine.prototype.getCurrentPosition = function() {
      return this.curEngine.getCurrentPosition();
    };

    Engine.prototype.getLoadedPercent = function() {
      return this.curEngine.getLoadedPercent();
    };

    Engine.prototype.getTotalTime = function() {
      return this.curEngine.getTotalTime();
    };

    Engine.prototype.getEngineType = function() {
      return this.curEngine.engineType;
    };

    Engine.prototype.getState = function() {
      return this.curEngine.getState();
    };

    return Engine;

  })();
  Events.mixTo(Engine);
  return Engine;
});

(function(root, factory) {
  if (typeof exports === 'object') {
    return module.exports = factory();
  } else if (typeof define === 'function' && define.amd) {
    return define('muplayer/player',['muplayer/core/cfg', 'muplayer/core/utils', 'muplayer/lib/events', 'muplayer/core/playlist', 'muplayer/core/engines/engine'], factory);
  } else {
    return root._mu.Player = factory(root._mu.cfg, root._mu.utils, root._mu.Events, root._mu.Playlist, root._mu.Engine);
  }
})(this, function(cfg, utils, Events, Playlist, Engine) {
  var EVENTS, Player, STATES, time2str, _ref;
  _ref = cfg.engine, EVENTS = _ref.EVENTS, STATES = _ref.STATES;
  time2str = utils.time2str;

  /**
   * muplayer的Player类（对应player.js）是对外暴露的接口，它封装了音频操作及播放列表（Playlist）逻辑，并屏蔽了对音频内核适配的细节对音频内核适配的细节。
   * <b>对一般应用场景，只需签出编译后的 <code>dist/js/player.min.js</code> 即可</b>。
   * 文档中 <code>player</code> 指代Player的实例。
   */
  Player = (function() {
    var instance;

    instance = null;

    Player.defaults = {
      baseDir: "" + cfg.cdn + cfg.version,
      mode: 'loop',
      mute: false,
      volume: 80,
      singleton: true,
      absoluteUrl: true
    };


    /**
     * Player初始化方法
     * @param {Object} options <table class="sub-params">
     *  <tr>
     *    <th>选项</th>
     *    <th>说明</th>
     *  </tr>
     *  <tr>
     *    <td>baseDir</td>
     *    <td>必填选项，指向MuPlayer编译后的静态文件资源目录。默认指向同版本线上CDN文件目录，但建议指向自己签出的dist文件夹目录，以规避潜在的flash跨域警告。</td>
     *  </tr>
     *  <tr>
     *    <td>mode</td>
     *    <td>默认值: 'loop'。加入播放器的歌曲列表的播放顺序逻辑，可选值为 'loop'（循环播放），'list'（列表播放，该列表播放到最后一首或第一首后则停止播放），'single'（单曲播放），'random'（随机），'list-random'（列表随机，与random的区别是保证已随机过的列表中歌曲均播放一次后，再对列表随机重置）。</td>
     *  </tr>
     *  <tr>
     *    <td>mute</td>
     *    <td>默认值: false。是否静音。</td>
     *  </tr>
     *  <tr>
     *    <td>volume</td>
     *    <td>默认值: 80。播放音量，取值范围0 - 100。</td>
     *  </tr>
     *  <tr>
     *    <td>singleton</td>
     *    <td>默认值: true。初始化的Player实例是否是单实例。如果希望一个页面中有多个播放实例并存，可以设成false</td>
     *  </tr>
     *  <tr>
     *    <td>absoluteUrl</td>
     *    <td>默认值: true。播放音频的链接是否要自动转化成绝对地址。</td>
     *  </tr>
     *  <tr>
     *    <td>engines</td>
     *    <td>初始化Engine，根据传入的engines来指定具体使用FlashMP3Core还是AudioCore来接管播放，当然也可以传入内核列表，Engine会根据内核所支持的音频格式做自适应。这里只看一下engines参数的可能值（其他参数一般无需配置，如有需要请查看engine.coffee的源码）：
     *    <pre>
     *    [{<br>
     *    <span class="ts"></span>constructor: 'FlashMP3Core',<br>
     *    <span class="ts"></span>args: { // 初始化FlashMP3Core的参数<br>
     *    <span class="ts2"></span>swf: 'muplayer_mp3.swf' // 对应的swf文件路径<br>
     *    <span class="ts"></span>}<br>
     *    }, {<br>
     *    <span class="ts"></span>constructor: 'FlashMP4Core',<br>
     *    <span class="ts"></span>args: { // 初始化FlashMP4Core的参数, FlashMP4Core支持m4a格式的音频文件<br>
     *    <span class="ts2"></span>swf: 'muplayer_mp4.swf' // 对应的swf文件路径<br>
     *    <span class="ts"></span>}<br>
     *    }, {<br>
     *    <span class="ts"></span>constructor: 'AudioCore'<br>
     *    }]
     *    </pre>
     *    </td>
     *  </tr></table>
     */

    function Player(options) {
      var baseDir, opts;
      this.opts = opts = $.extend({}, Player.defaults, options);
      baseDir = opts.baseDir;
      if (baseDir === false) {
        baseDir = '';
      } else if (!baseDir) {
        throw "baseDir must be set! Usually, it should point to the MuPlayer's dist directory.";
      }
      if (baseDir && !baseDir.endsWith('/')) {
        baseDir = baseDir + '/';
      }
      if (opts.singleton) {
        if (instance) {
          return instance;
        }
        instance = this;
      }
      this.playlist = new Playlist({
        absoluteUrl: opts.absoluteUrl
      });
      this.playlist.setMode(opts.mode);
      this._initEngine(new Engine({
        baseDir: baseDir,
        engines: opts.engines
      }));
      this.setMute(opts.mute);
      this.setVolume(opts.volume);
    }

    Player.prototype._initEngine = function(engine) {
      return this.engine = engine.on(EVENTS.STATECHANGE, (function(_this) {
        return function(e) {
          var st;
          st = e.newState;
          _this.trigger('player:statechange', e);
          _this.trigger(st);
          if (st === STATES.END) {
            return _this.next(true);
          }
        };
      })(this)).on(EVENTS.POSITIONCHANGE, (function(_this) {
        return function(pos) {
          return _this.trigger('timeupdate', pos);
        };
      })(this)).on(EVENTS.PROGRESS, (function(_this) {
        return function(progress) {
          return _this.trigger('progress', progress);
        };
      })(this)).on(EVENTS.ERROR, (function(_this) {
        return function(e) {
          return _this.trigger('error', e);
        };
      })(this));
    };


    /**
     * 若播放列表中有歌曲就开始播放。会派发 <code>player:play</code> 事件。
     * @param {Number} startTime 指定歌曲播放的起始位置，单位：毫秒。
     * @return {player}
     */

    Player.prototype.play = function(startTime) {
      var def, engine, play, st;
      startTime = ~~startTime;
      def = $.Deferred();
      engine = this.engine;
      play = (function(_this) {
        return function() {
          if (startTime) {
            engine.setCurrentPosition(startTime);
          } else {
            engine.play();
          }
          _this.trigger('player:play', startTime);
          return def.resolve();
        };
      })(this);
      st = this.getState();
      if ((st === STATES.NOT_INIT || st === STATES.STOP || st === STATES.END) || st === STATES.BUFFERING && this.curPos() === 0) {
        this._fetch().done((function(_this) {
          return function() {
            return play();
          };
        })(this));
      } else {
        play();
      }
      return def.promise();
    };


    /**
     * 若player正在播放，则暂停播放 (这时，如果再执行play方法，则从暂停位置继续播放)。会派发 <code>player:pause</code> 事件。
     * @return {player}
     */

    Player.prototype.pause = function() {
      this.engine.pause();
      this.trigger('player:pause');
      return this;
    };


    /**
     * 停止播放，会将当前播放位置重置。即stop后执行play，将从音频头部重新播放。会派发 <code>player:stop</code> 事件。
     * @return {player}
     */

    Player.prototype.stop = function() {
      this.engine.stop();
      this.trigger('player:stop');
      return this;
    };


    /**
     * stop() + play()的快捷方式。
     * @return {player}
     */

    Player.prototype.replay = function() {
      return this.stop().play();
    };


    /**
     * 播放前一首歌。会派发 <code>player:prev</code> 事件，事件参数：
     * <pre>cur // 调用prev时正在播放的歌曲</pre>
     * @return {player}
     */

    Player.prototype.prev = function() {
      var cur;
      cur = this.getCur();
      this.stop();
      if (this.getSongsNum() && this.playlist.prev()) {
        this.trigger('player:prev', {
          cur: cur
        });
        this.play();
      }
      return this;
    };


    /**
     * 播放下一首歌。参数auto是布尔值，代表是否是因自动切歌而触发的（比如因为一首歌播放完会自动触发next方法，这时auto为true，其他主动调用auto应为undefined）。
     * 会派发 <code>player:next</code> 事件，事件参数：
     * <pre>auto // 是否为自动切歌
     * cur  // 调用next时正在播放的歌曲</pre>
     * @return {player}
     */

    Player.prototype.next = function(auto) {
      var cur;
      cur = this.getCur();
      this.stop();
      if (this.getSongsNum() && this.playlist.next()) {
        this.trigger('player:next', {
          auto: auto,
          cur: cur
        });
        this.play();
      }
      return this;
    };


    /**
     * 获取当前歌曲（根据业务逻辑和选链_fetch方法的具体实现可以是音频文件url，也可以是标识id，默认直接传入音频文件url即可）。
     * 如果之前没有主动执行过setCur，则认为播放列表的第一首歌是当前歌曲。
     * @return {String}
     */

    Player.prototype.getCur = function() {
      var cur, pl;
      pl = this.playlist;
      cur = pl.cur;
      if (!cur && this.getSongsNum()) {
        cur = pl.list[0];
        pl.setCur(cur);
      }
      return cur + '';
    };


    /**
     * 设置当前歌曲。
     * @param {String} sid 可以是音频文件url，也可以是音频文件id（如果是文件id，则要自己重写_fetch方法，决定如何根据id获得相应音频的实际地址）。
     * @return {player}
     */

    Player.prototype.setCur = function(sid) {
      var pl;
      pl = this.playlist;
      if (!sid && this.getSongsNum()) {
        sid = pl.list[0];
      }
      if (sid && this._sid !== sid) {
        pl.setCur(sid);
        this._sid = sid;
        this.stop();
      }
      return this;
    };


    /**
     * 当前播进度（单位秒）。
     * @return {Number}
     */

    Player.prototype.curPos = function(format) {
      var pos;
      pos = this.engine.getCurrentPosition() / 1000;
      if (format) {
        return time2str(pos);
      } else {
        return pos;
      }
    };


    /**
     * 单曲总时长（单位秒）。
     * @return {Number}
     */

    Player.prototype.duration = function(format) {
      var duration;
      duration = this.engine.getTotalTime() / 1000;
      if (format) {
        return time2str(duration);
      } else {
        return duration;
      }
    };


    /**
     * 将音频资源添加到播放列表
     * @param {String|Array} sid 要添加的单曲资源或标识，为数组则代表批量添加。会派发 <code>player:add</code> 事件。
     * @return {player}
     */

    Player.prototype.add = function(sid) {
      if (sid) {
        this.playlist.add(sid);
      }
      this.trigger('player:add', sid);
      return this;
    };


    /**
     * 从播放列表中移除指定资源，若移除资源后列表为空则触发reset。会派发 <code>player:remove</code> 事件。
     * @param {String|Array} sid 要移除的资源标识（与add方法参数相对应）。
     * @return {player}
     */

    Player.prototype.remove = function(sid) {
      if (sid) {
        this.playlist.remove(sid);
      }
      if (!this.getSongsNum()) {
        this.reset();
      }
      this.trigger('player:remove', sid);
      return this;
    };


    /**
     * 播放列表和内核资源重置。会派发 <code>player:reset</code> 事件。
     * 如有特别需要可以自行扩展，比如通过监听 <code>player:reset</code> 来重置相关业务逻辑的标志位或事件等。
     * @return {player}
     */

    Player.prototype.reset = function() {
      this.playlist.reset();
      this.engine.reset();
      this.trigger('player:reset');
      return this;
    };


    /**
     * 获取播放内核当前状态。所有可能状态值参见 <code>cfg.coffee</code> 中的 <code>engine.STATES</code> 声明。
     * @return {String}
     */

    Player.prototype.getState = function() {
      return this.engine.getState();
    };


    /**
     * 设置当前播放资源的url。一般而言，这个方法是私有方法，供_fetch等内部方法中调用，客户端无需关心。
     * 但出于调试和灵活性的考虑，依然之暴露为公共方法。
     * @param {String} url
     * @return {player}
     */

    Player.prototype.setUrl = function(url) {
      this.engine.setUrl(url);
      this.trigger('player:setUrl', url);
      return this;
    };


    /**
     * 获取当前播放资源的url。
     * @return {String}
     */

    Player.prototype.getUrl = function() {
      return this.engine.getUrl();
    };


    /**
     * 设置播放器音量。
     * @param {Number} volume 合法范围：0 - 100，0是静音。注意volume与mute不会相互影响，即便setVolume(0)，getMute()的结果依然维持不变。反之亦然。
     */

    Player.prototype.setVolume = function(volume) {
      this.engine.setVolume(volume);
      this.trigger('player:setVolume', volume);
      return this;
    };


    /**
     * 获取播放器音量。返回值范围：0 - 100
     * @return {Number}
     */

    Player.prototype.getVolume = function() {
      return this.engine.getVolume();
    };


    /**
     * 设置是否静音。
     * @param {Boolean} mute true为静音，flase为不静音。
     * @return {player}
     */

    Player.prototype.setMute = function(mute) {
      this.engine.setMute(mute);
      this.trigger('player:setMute', mute);
      return this;
    };


    /**
     * 获取静音状态。
     * @return {Boolean}
     */

    Player.prototype.getMute = function() {
      return this.engine.getMute();
    };


    /**
     * 检验内核是否支持播放指定的音频格式。
     * @param {String} type 标识音频格式（或音频文件后缀）的字符串，如'mp3', 'aac'等。
     * @return {Boolean}
     */

    Player.prototype.canPlayType = function(type) {
      return this.engine.canPlayType(type);
    };


    /**
     * 播放列表中的歌曲总数。这一个快捷方法，如有更多需求，可自行获取播放列表：player.playlist.list。
     * @return {Number}
     */

    Player.prototype.getSongsNum = function() {
      return this.playlist.list.length;
    };


    /**
     * 设置列表播放的模式。
     * @param {String} mode 可选值参见前文对初始化Player方法的options参数描述。
     * @return {player}
     */

    Player.prototype.setMode = function(mode) {
      this.playlist.setMode(mode);
      this.trigger('player:setMode', mode);
      return this;
    };


    /**
     * 获取列表播放的模式。
     * @return {String}
     */

    Player.prototype.getMode = function() {
      return this.playlist.mode;
    };

    Player.prototype._fetch = function() {
      var def;
      def = $.Deferred();
      if (this.getUrl() === this.getCur()) {
        def.resolve();
      } else {
        setTimeout((function(_this) {
          return function() {
            _this.setUrl(_this.getCur());
            return def.resolve();
          };
        })(this), 0);
      }
      return def.promise();
    };

    return Player;

  })();
  Events.mixTo(Player);
  return Player;
});

