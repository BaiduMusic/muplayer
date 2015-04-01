// @license
// Baidu Music Player: 0.9.2
// -------------------------
// (c) 2014 FE Team of Baidu Music
// Can be freely distributed under the BSD license.
;(function($) {
    var ObjProto = Object.prototype,
        toString = ObjProto.toString;

    $.isString = function(obj) {
        return toString.call(obj) === '[object String]';
    }

    $.isNumeric = function(obj) {
        return toString.call(obj) === '[object Number]';
    }

    // 参考: https://github.com/dexteryy/OzJS/blob/master/oz.js
    $.getScript = function(url, op) {
        var doc = document,
            s = doc.createElement('script');
            s.async = 'async';

        if (!op) {
            op = {};
        } else if ($.isFunction(op)) {
            op = {
                callback: op
            };
        }

        if (op.charset) {
            s.charset = op.charset;
        }

        s.src = url;

        var h = doc.getElementsByTagName('head')[0];

        s.onload = s.onreadystatechange = function(__, isAbort) {
            if (isAbort || !s.readyState || /loaded|complete/.test(s.readyState)) {
                s.onload = s.onreadystatechange = null;
                if (h && s.parentNode) {
                    h.removeChild(s);
                }
                s = undefined;
                if (!isAbort && op.callback) {
                    op.callback();
                }
            }
        };

        h.insertBefore(s, h.firstChild);
    }
})(Zepto);
;(function(root, factory) {
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
        INIT_FAIL: 'engine:init_fail',
        WAITING_TIMEOUT: 'engine:waiting_timeout'
      },
      STATES: {
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
  var ArrayProto, NumProto, ObjProto, StrProto, baseCreate, executeBound, extReg, hasOwnProperty, j, len, name, nativeCreate, push, ref, slice, toString, utils;
  utils = {};
  StrProto = String.prototype;
  NumProto = Number.prototype;
  ObjProto = Object.prototype;
  ArrayProto = Array.prototype;
  push = ArrayProto.push;
  slice = ArrayProto.slice;
  toString = ObjProto.toString;
  hasOwnProperty = ObjProto.hasOwnProperty;
  nativeCreate = Object.create;
  extReg = /\.(\w+)(\?.*)?$/;
  ref = ['Arguments', 'Function', 'String', 'Number', 'Date', 'RegExp'];
  for (j = 0, len = ref.length; j < len; j++) {
    name = ref[j];
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
  baseCreate = function(prototype) {
    var result;
    if (!$.isPlainObject(prototype)) {
      return {};
    }
    if (nativeCreate) {
      return nativeCreate(prototype);
    }
    Ctor.prototype = prototype;
    result = new Ctor;
    Ctor.prototype = null;
    return result;
  };
  executeBound = function(sourceFunc, boundFunc, context, callingContext, args) {
    var result, self;
    if (!(callingContext instanceof boundFunc)) {
      return sourceFunc.apply(context, args);
    }
    self = baseCreate(sourceFunc.prototype);
    result = sourceFunc.apply(self, args);
    if ($.isPlainObject(result)) {
      return result;
    }
    return self;
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
      var i, item, k, len1, rand, shuffled;
      i = 0;
      shuffled = [];
      for (k = 0, len1 = list.length; k < len1; k++) {
        item = list[k];
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
      pad = function(source, length) {
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
      if (hour) {
        r.push(hour);
      }
      r.push(pad(minute, 2));
      r.push(pad(second, 2));
      return r.join(':');
    },
    namespace: function() {
      var a, arg, d, i, k, l, len1, o, period, ref1;
      a = arguments;
      period = '.';
      for (k = 0, len1 = a.length; k < len1; k++) {
        arg = a[k];
        o = cfg.namespace;
        if (arg.indexOf(period) > -1) {
          d = arg.split(period);
          ref1 = [0, d.length], i = ref1[0], l = ref1[1];
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
    partial: function(func) {
      var bound, boundArgs;
      boundArgs = slice.call(arguments, 1);
      bound = function() {
        var args, i, length, position;
        position = 0;
        length = boundArgs.length;
        args = Array(length);
        i = 0;
        while (i < length) {
          args[i] = boundArgs[i] === utils ? arguments[position++] : boundArgs[i];
          i++;
        }
        while (position < arguments.length) {
          args.push(arguments[position++]);
        }
        return executeBound(func, bound, this, this, args);
      };
      return bound;
    },
    wrap: function(func, wrapper) {
      return utils.partial(wrapper, func);
    },
    toAbsoluteUrl: function(url) {
      var div;
      div = document.createElement('div');
      div.innerHTML = '<a></a>';
      div.firstChild.href = url;
      div.innerHTML = div.innerHTML;
      return div.firstChild.href;
    },
    getExt: function(url) {
      var ext;
      ext = '';
      if (extReg.test(decodeURIComponent(url))) {
        ext = RegExp.$1.toLocaleLowerCase();
      }
      return ext;
    }
  });
  return utils;
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
                        clearTimeout(self._timer);
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

var indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

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
        this.list.length = 0;
      } else {
        this.list = [];
      }
      return this;
    };

    Playlist.prototype.destroy = function() {
      return this.reset().off();
    };

    Playlist.prototype._resetListRandom = function(index) {
      var j, ref, results;
      if (this.mode === 'list-random') {
        index = index || 0;
        this._listRandomIndex = index;
        this._listRandom = utils.shuffle((function() {
          results = [];
          for (var j = 0, ref = this.list.length; 0 <= ref ? j < ref : j > ref; 0 <= ref ? j++ : j--){ results.push(j); }
          return results;
        }).apply(this));
        this.cur = this.list[this._listRandom[index]];
        return this.trigger('playlist:resetListRandom');
      }
    };

    Playlist.prototype._formatSid = function(sids) {
      var absoluteUrl, format, sid;
      absoluteUrl = this.opts.absoluteUrl;
      format = function(sid) {
        return absoluteUrl && utils.toAbsoluteUrl(sid) || '' + sid;
      };
      return $.isArray(sids) && ((function() {
        var j, len, results;
        results = [];
        for (j = 0, len = sids.length; j < len; j++) {
          sid = sids[j];
          if (sid) {
            results.push(format(sid));
          }
        }
        return results;
      })()) || format(sids);
    };

    Playlist.prototype.setMode = function(mode) {
      if (mode === 'single' || mode === 'random' || mode === 'list-random' || mode === 'list' || mode === 'loop') {
        this.mode = mode;
      }
      return this._resetListRandom();
    };

    Playlist.prototype.add = function(sid, unshift) {
      if (unshift == null) {
        unshift = true;
      }
      sid = this._formatSid(sid);
      this.remove(sid);
      if ($.isArray(sid)) {
        if (sid.length) {
          this.list = unshift && sid.concat(this.list) || this.list.concat(sid);
        }
      } else if (sid) {
        this.list[unshift && 'unshift' || 'push'](sid);
      }
      this.trigger('playlist:add', sid);
      return this._resetListRandom();
    };

    Playlist.prototype.remove = function(sid) {
      var id, j, len, remove;
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
        for (j = 0, len = sid.length; j < len; j++) {
          id = sid[j];
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
      if (i === -1) {
        i = 0;
      }
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
            this.cur = '';
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
      if (i === -1) {
        i = 0;
      }
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
            this.cur = '';
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
      sid = this._formatSid(sid);
      if (indexOf.call(this.list, sid) < 0) {
        this.add(sid);
      }
      return this.cur = sid;
    };

    return Playlist;

  })();
  Events.mixTo(Playlist);
  return Playlist;
});

var indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

(function(root, factory) {
  if (typeof exports === 'object') {
    return module.exports = factory();
  } else if (typeof define === 'function' && define.amd) {
    return define('muplayer/core/engines/engineCore',['muplayer/core/cfg', 'muplayer/core/utils', 'muplayer/lib/events'], factory);
  } else {
    return root._mu.EngineCore = factory(_mu.cfg, _mu.utils, _mu.Events);
  }
})(this, function(cfg, utils, Events) {
  var EVENTS, EngineCore, STATES, availableStates, k, ref, v;
  ref = cfg.engine, EVENTS = ref.EVENTS, STATES = ref.STATES;
  availableStates = (function() {
    var results;
    results = [];
    for (k in STATES) {
      v = STATES[k];
      results.push(v);
    }
    return results;
  })();
  EngineCore = (function() {
    function EngineCore() {}

    EngineCore.prototype._supportedTypes = [];

    EngineCore.prototype.getSupportedTypes = function() {
      return this._supportedTypes;
    };

    EngineCore.prototype.canPlayType = function(type) {
      if (type === 'mp4a') {
        type = 'm4a';
      }
      return $.inArray(type, this.getSupportedTypes()) !== -1;
    };

    EngineCore.prototype.reset = function() {
      this.stop();
      this.setUrl();
      this.trigger(EVENTS.PROGRESS, 0);
      this.trigger(EVENTS.POSITIONCHANGE, 0);
      return this;
    };

    EngineCore.prototype.destroy = function() {
      return this.reset().off();
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
      var oldState, ref1;
      if (indexOf.call(availableStates, st) < 0 || st === this._state) {
        return;
      }
      if ((st === STATES.BUFFERING || st === STATES.CANPLAYTHROUGH) && ((ref1 = this._state) === STATES.END || ref1 === STATES.STOP)) {
        return;
      }
      if ((st === STATES.PREBUFFER || st === STATES.BUFFERING) && this._state === STATES.PAUSE) {
        return;
      }
      oldState = this._state;
      this._state = st;
      return this.trigger(EVENTS.STATECHANGE, {
        oldState: oldState,
        newState: st
      });
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

var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty,
  slice = [].slice;

(function(root, factory) {
  if (typeof exports === 'object') {
    return module.exports = factory();
  } else if (typeof define === 'function' && define.amd) {
    return define('muplayer/core/engines/audioCore',['muplayer/core/cfg', 'muplayer/core/utils', 'muplayer/core/engines/engineCore', 'muplayer/lib/modernizr.audio'], factory);
  } else {
    return root._mu.AudioCore = factory(_mu.cfg, _mu.utils, _mu.EngineCore, _mu.Modernizr);
  }
})(this, function(cfg, utils, EngineCore, Modernizr) {
  var AudioCore, ERRCODE, EVENTS, STATES, TYPES, ref, win;
  win = window;
  ref = cfg.engine, TYPES = ref.TYPES, EVENTS = ref.EVENTS, STATES = ref.STATES, ERRCODE = ref.ERRCODE;
  AudioCore = (function(superClass) {
    extend(AudioCore, superClass);

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
      var _eventHandlers, audio, k, least, levels, opts, playEmpty, v;
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
      _eventHandlers = {};
      audio = new Audio();
      audio.preload = opts.preload;
      audio.autoplay = opts.autoplay;
      audio.loop = false;
      audio.on = function(type, listener) {
        var listeners;
        audio.addEventListener(type, listener, false);
        listeners = _eventHandlers[type];
        if (!listeners) {
          listeners = [];
        }
        listeners.push(listener);
        return audio;
      };
      audio.off = function(type, listener) {
        var i, len, listeners;
        if (!type && !listener) {
          for (type in _eventHandlers) {
            listeners = _eventHandlers[type];
            for (i = 0, len = listeners.length; i < len; i++) {
              listener = listeners[i];
              audio.removeEventListener(type, listener, false);
            }
          }
        } else {
          audio.removeEventListener(type, listener, false);
        }
        return audio;
      };
      this.audio = audio;
      this._needCanPlay(['play', 'setCurrentPosition']);
      this.setState(STATES.STOP);
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
      var audio, canPlayThrough, errorTimer, progress, progressTimer, ref1, self, trigger;
      self = this;
      audio = this.audio, trigger = this.trigger;
      ref1 = [null, null, false], errorTimer = ref1[0], progressTimer = ref1[1], canPlayThrough = ref1[2];
      this.trigger = function(type, listener) {
        if (self.getUrl() !== self.opts.emptyMP3) {
          return trigger.call(self, type, listener);
        }
      };
      progress = function(per) {
        per = per || self.getLoadedPercent();
        self.trigger(EVENTS.PROGRESS, per);
        if (per === 1) {
          clearInterval(progressTimer);
          canPlayThrough = true;
          return self.setState(STATES.CANPLAYTHROUGH);
        }
      };
      return audio.on('loadstart', function() {
        canPlayThrough = false;
        clearInterval(progressTimer);
        progressTimer = setInterval(function() {
          return progress();
        }, 50);
        return self.setState(STATES.PREBUFFER);
      }).on('playing', function() {
        clearTimeout(errorTimer);
        return self.setState(STATES.PLAYING);
      }).on('pause', function() {
        return self.setState(self.getCurrentPosition() && STATES.PAUSE || STATES.STOP);
      }).on('ended', function() {
        return self.setState(STATES.END);
      }).on('error', function(e) {
        clearTimeout(errorTimer);
        return errorTimer = setTimeout(function() {
          return self.trigger(EVENTS.ERROR, e);
        }, 2000);
      }).on('waiting', function() {
        return self.setState(STATES.PREBUFFER);
      }).on('loadeddata', function() {
        return self.setState(STATES.BUFFERING);
      }).on('timeupdate', function() {
        return self.trigger(EVENTS.POSITIONCHANGE, self.getCurrentPosition());
      }).on('progress', function(e) {
        var loaded, total;
        clearInterval(progressTimer);
        if (!canPlayThrough) {
          loaded = e.loaded || 0;
          total = e.total || 1;
          return progress(loaded && (loaded / total).toFixed(2) * 1);
        }
      });
    };

    AudioCore.prototype._needCanPlay = function(fnames) {
      var audio, i, len, name, results, self;
      self = this;
      audio = this.audio;
      results = [];
      for (i = 0, len = fnames.length; i < len; i++) {
        name = fnames[i];
        results.push(this[name] = utils.wrap(this[name], function() {
          var args, fn, handle, t;
          fn = arguments[0], args = 2 <= arguments.length ? slice.call(arguments, 1) : [];
          t = null;
          handle = function() {
            clearTimeout(t);
            fn.apply(self, args);
            return audio.off('canplay', handle);
          };
          if (/webkit/.test(navigator.userAgent.toLowerCase())) {
            if (audio.readyState < 3) {
              audio.on('canplay', handle);
            } else {
              fn.apply(self, args);
            }
          } else {
            t = setTimeout(function() {
              var e;
              try {
                return fn.apply(self, args);
              } catch (_error) {
                e = _error;
                return typeof console !== "undefined" && console !== null ? typeof console.error === "function" ? console.error('error: ', e) : void 0 : void 0;
              }
            }, 1000);
            audio.on('canplay', handle);
          }
          return self;
        }));
      }
      return results;
    };

    AudioCore.prototype.destroy = function() {
      AudioCore.__super__.destroy.call(this);
      this.audio.off();
      return this;
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
        return;
      } finally {
        this.pause();
      }
      return this;
    };

    AudioCore.prototype.setUrl = function(url) {
      if (url) {
        this.audio.src = url;
        this.audio.load();
      }
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
        return;
      } finally {
        this.play();
      }
      return this;
    };

    AudioCore.prototype.getCurrentPosition = function() {
      return ~~(this.audio.currentTime * 1000);
    };

    AudioCore.prototype.getLoadedPercent = function() {
      var audio, be, bl, buffered, duration, ref1;
      audio = this.audio;
      be = audio.currentTime;
      buffered = audio.buffered;
      if (buffered) {
        bl = buffered.length;
        while (bl--) {
          if ((buffered.start(bl) <= (ref1 = audio.currentTime) && ref1 <= buffered.end(bl))) {
            be = buffered.end(bl);
            break;
          }
        }
      }
      duration = this.getTotalTime() / 1000;
      be = be > duration ? duration : be;
      return duration && (be / duration).toFixed(2) * 1 || 0;
    };

    AudioCore.prototype.getTotalTime = function() {
      var bl, buffered, currentTime, duration, ref1;
      ref1 = this.audio, duration = ref1.duration, buffered = ref1.buffered, currentTime = ref1.currentTime;
      duration = ~~duration;
      if (duration === 0 && buffered) {
        bl = buffered.length;
        if (bl > 0) {
          duration = buffered.end(--bl);
        } else {
          duration = currentTime;
        }
      }
      return duration && duration * 1000 || 0;
    };

    return AudioCore;

  })(EngineCore);
  return AudioCore;
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
                    ], factory);
  } else {
    return root._mu.Engine = factory(
            _mu.cfg
            , _mu.utils
            , _mu.Events
            , _mu.EngineCore
            , _mu.AudioCore
                    );
  }
})(this, function(cfg, utils, Events, EngineCore, AudioCore, FlashMP3Core, FlashMP4Core) {
  var EVENTS, Engine, STATES, ref, timerResolution;
  ref = cfg.engine, EVENTS = ref.EVENTS, STATES = ref.STATES;
  timerResolution = cfg.timerResolution;
  Engine = (function() {
    Engine.el = '<div id="muplayer_container_{{DATETIME}}" style="width: 1px; height: 1px; background: transparent; position: absolute; left: 0; top: 0;"></div>';

    Engine.prototype.defaults = {
      engines: [
                                {
                    type: AudioCore
                }
            ]
    };

    function Engine(options) {
      this.opts = $.extend({}, this.defaults, options);
      this._initEngines();
    }

    Engine.prototype._initEngines = function() {
      var $el, args, engine, i, j, len, opts, ref1, type;
      this.engines = [];
      opts = this.opts;
      this.$el = $el = $(Engine.el.replace(/{{DATETIME}}/g, +new Date())).appendTo('body');
      ref1 = opts.engines;
      for (i = j = 0, len = ref1.length; j < len; i = ++j) {
        engine = ref1[i];
        type = engine.type, args = engine.args;
        args = args || {};
        args.baseDir = opts.baseDir;
        args.$el = $el;
        try {
          if (!$.isFunction(type)) {
            type = eval(type);
          }
          engine = new type(args);
        } catch (_error) {
          throw new Error("Missing engine type: " + (String(engine.type)));
        }
        if (engine._test && engine._test()) {
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
      var bindEvents, errorHandle, oldEngine, positionHandle, progressHandle, self, statechangeHandle, unbindEvents;
      self = this;
      this._lastE = {};
      statechangeHandle = function(e) {
        var newState, oldState;
        newState = e.newState, oldState = e.oldState;
        if (oldState === self._lastE.oldState && newState === self._lastE.newState) {
          return;
        }
        self._lastE = {
          oldState: oldState,
          newState: newState
        };
        self.trigger(EVENTS.STATECHANGE, e);
        if (newState === STATES.CANPLAYTHROUGH && (oldState === STATES.PLAYING || oldState === STATES.PAUSE)) {
          return self.setState(oldState);
        }
      };
      positionHandle = function(pos) {
        return self.trigger(EVENTS.POSITIONCHANGE, pos);
      };
      progressHandle = function(progress) {
        return self.trigger(EVENTS.PROGRESS, progress);
      };
      errorHandle = function(err) {
        return self.trigger(EVENTS.ERROR, err);
      };
      bindEvents = function(engine) {
        return engine.on(EVENTS.STATECHANGE, statechangeHandle).on(EVENTS.POSITIONCHANGE, positionHandle).on(EVENTS.PROGRESS, progressHandle).on(EVENTS.ERROR, errorHandle);
      };
      unbindEvents = function(engine) {
        return engine.off(EVENTS.STATECHANGE, statechangeHandle).off(EVENTS.POSITIONCHANGE, positionHandle).off(EVENTS.PROGRESS, progressHandle).off(EVENTS.ERROR, errorHandle);
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
      if (type === 'mp4a') {
        type = 'm4a';
      }
      return $.inArray(type, this.getSupportedTypes()) !== -1;
    };

    Engine.prototype.getSupportedTypes = function() {
      var engine, j, len, ref1, types;
      types = [];
      ref1 = this.engines;
      for (j = 0, len = ref1.length; j < len; j++) {
        engine = ref1[j];
        types = types.concat(engine.getSupportedTypes());
      }
      return types;
    };

    Engine.prototype.switchEngineByType = function(type) {
      var engine, j, len, match, ref1;
      match = false;
      ref1 = this.engines;
      for (j = 0, len = ref1.length; j < len; j++) {
        engine = ref1[j];
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

    Engine.prototype.destroy = function() {
      var engine, j, len, ref1;
      this.reset().off();
      ref1 = this.engines;
      for (j = 0, len = ref1.length; j < len; j++) {
        engine = ref1[j];
        engine.destroy();
      }
      this.engines.length = 0;
      this.$el.off().remove();
      delete this.curEngine;
      return this;
    };

    Engine.prototype.setUrl = function(url) {
      var ext;
      ext = utils.getExt(url);
      if (this.canPlayType(ext)) {
        if (!this.curEngine.canPlayType(ext)) {
          this.switchEngineByType(ext);
        }
      } else {
        throw new Error("Can not play with: " + ext);
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
      this.trigger(EVENTS.POSITIONCHANGE, this.getCurrentPosition());
      this.setState(STATES.PAUSE);
      return this;
    };

    Engine.prototype.stop = function() {
      this.curEngine.stop();
      this.trigger(EVENTS.POSITIONCHANGE, 0);
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

    return Engine;

  })();
  Events.mixTo(Engine);
  return Engine;
});

var slice = [].slice;

(function(root, factory) {
  if (typeof exports === 'object') {
    return module.exports = factory();
  } else if (typeof define === 'function' && define.amd) {
    return define('muplayer/player',['muplayer/core/cfg', 'muplayer/core/utils', 'muplayer/lib/Timer', 'muplayer/lib/events', 'muplayer/core/playlist', 'muplayer/core/engines/engine'], factory);
  } else {
    return root._mu.Player = factory(_mu.cfg, _mu.utils, _mu.Timer, _mu.Events, _mu.Playlist, _mu.Engine);
  }
})(this, function(cfg, utils, Timer, Events, Playlist, Engine) {
  var EVENTS, Player, STATES, ctrl, ref, time2str;
  ref = cfg.engine, EVENTS = ref.EVENTS, STATES = ref.STATES;
  time2str = utils.time2str;
  ctrl = function(fname, auto) {
    var pl, play;
    if (fname !== 'prev' && fname !== 'next') {
      return this;
    }
    this.stop();
    pl = this.playlist;
    play = (function(_this) {
      return function() {
        var args;
        args = {
          cur: _this.getCur()
        };
        if (auto) {
          args.auto = auto;
        }
        _this.trigger("player:" + fname, args);
        return _this.play();
      };
    })(this);
    if (this.getSongsNum()) {
      if (!pl.cur) {
        play();
      } else if (pl[fname].call(pl, auto)) {
        play();
      } else {
        this.trigger("player:" + fname + ":fail", auto);
      }
    }
    return this;
  };

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
      absoluteUrl: true,
      maxRetryTimes: 1,
      maxWaitingTime: 4,
      recoverMethodWhenWaitingTimeout: 'retry',
      fetch: function() {
        var cur, def;
        def = $.Deferred();
        cur = this.getCur();
        setTimeout((function(_this) {
          return function() {
            _this.setUrl(cur);
            return def.resolve();
          };
        })(this), 0);
        return def.promise();
      }
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
     *    <span class="ts"></span>type: 'FlashMP3Core',<br>
     *    <span class="ts"></span>args: { // 初始化FlashMP3Core的参数<br>
     *    <span class="ts2"></span>swf: 'muplayer_mp3.swf' // 对应的swf文件路径<br>
     *    <span class="ts"></span>}<br>
     *    }, {<br>
     *    <span class="ts"></span>type: 'FlashMP4Core',<br>
     *    <span class="ts"></span>args: { // 初始化FlashMP4Core的参数, FlashMP4Core支持m4a格式的音频文件<br>
     *    <span class="ts2"></span>swf: 'muplayer_mp4.swf' // 对应的swf文件路径<br>
     *    <span class="ts"></span>}<br>
     *    }, {<br>
     *    <span class="ts"></span>type: 'AudioCore'<br>
     *    }]
     *    </pre>
     *    </td>
     *  </tr></table>
     */

    function Player(options) {
      var baseDir, opts;
      this.opts = opts = $.extend({}, Player.defaults, options);
      this.waitingTimer = new Timer(100);
      this._checkFrozen(['play', 'pause', 'stop', 'setCurrentPosition', 'setVolume', 'setMute', 'next', 'prev', 'retry', '_startWaitingTimer']);
      baseDir = opts.baseDir;
      if (baseDir === false) {
        baseDir = '';
      } else if (!baseDir) {
        throw new Error("baseDir must be set! Usually, it should point to the MuPlayer's dist directory.");
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
      this.reset();
    }

    Player.prototype._initEngine = function(engine) {
      var recover, self;
      self = this;
      recover = this.opts.recoverMethodWhenWaitingTimeout;
      this.engine = engine;
      return this.engine.on(EVENTS.STATECHANGE, function(e) {
        var st;
        st = e.newState;
        self.trigger('player:statechange', e);
        self.trigger(st);
        if (st === STATES.END) {
          return self._clearWaitingTimer().next(true);
        }
      }).on(EVENTS.POSITIONCHANGE, function(pos) {
        var st;
        if (!pos) {
          return;
        }
        st = self.getState();
        self.trigger('timeupdate', pos);
        if (self.getUrl() && (st === STATES.PLAYING || st === STATES.PREBUFFER || st === STATES.BUFFERING || st === STATES.CANPLAYTHROUGH)) {
          return self._startWaitingTimer();
        }
      }).on(EVENTS.PROGRESS, function(progress) {
        return self.trigger('progress', progress);
      }).on(EVENTS.ERROR, function(e) {
        if (typeof console !== "undefined" && console !== null) {
          if (typeof console.error === "function") {
            console.error('error: ', e);
          }
        }
        return self.trigger('error', e);
      }).on(EVENTS.WAITING_TIMEOUT, function() {
        if (recover === 'retry' || recover === 'next') {
          self[recover]();
        }
        return self.trigger('player:waiting_timeout');
      });
    };

    Player.prototype.retry = function() {
      var ms, url;
      if (this._retryTimes < this.opts.maxRetryTimes) {
        this._retryTimes++;
        url = this.getUrl();
        ms = this.engine.getCurrentPosition();
        this.pause().setUrl(url).engine.setCurrentPosition(ms);
        this._startWaitingTimer().trigger('player:retry', this._retryTimes);
      } else {
        this._retryTimes = 0;
        this.trigger('player:retry:max');
      }
      return this;
    };


    /**
     * 若播放列表中有歌曲就开始播放。会派发 <code>player:play</code> 事件。
     * @param {Number} startTime 指定歌曲播放的起始位置，单位：毫秒。
     * @return {player}
     */

    Player.prototype.play = function(startTime) {
      var def, engine, play, self, st;
      self = this;
      engine = this.engine;
      def = $.Deferred();
      play = function() {
        if (self.getUrl() && !self._frozen) {
          self._startWaitingTimer();
          engine.play();
          if ($.isNumeric(startTime)) {
            engine.setCurrentPosition(startTime);
          }
        }
        return def.resolve();
      };
      st = this.getState();
      if ((st === STATES.STOP || st === STATES.END) || !this.getUrl()) {
        this.trigger('player:fetch:start');
        this.opts.fetch.call(this).done(function() {
          play();
          return self.trigger('player:fetch:done');
        }).fail(function(err) {
          return self.trigger('player:fetch:fail', err);
        });
      } else {
        play();
      }
      self.trigger('player:play', startTime);
      return def.promise();
    };


    /**
     * 若player正在播放，则暂停播放 (这时，如果再执行play方法，则从暂停位置继续播放)。会派发 <code>player:pause</code> 事件。
     * @return {player}
     */

    Player.prototype.pause = function() {
      this.engine.pause();
      this._clearWaitingTimer().trigger('player:pause');
      return this;
    };


    /**
     * 停止播放，会将当前播放位置重置。即stop后执行play，将从音频头部重新播放。会派发 <code>player:stop</code> 事件。
     * @return {player}
     */

    Player.prototype.stop = function() {
      this.engine.stop();
      this._clearWaitingTimer().trigger('player:stop');
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
      return ctrl.apply(this, ['prev']);
    };


    /**
     * 播放下一首歌。参数auto是布尔值，代表是否是因自动切歌而触发的（比如因为一首歌播放完会自动触发next方法，这时auto为true，其他主动调用auto应为undefined）。
     * 会派发 <code>player:next</code> 事件，事件参数：
     * <pre>auto // 是否为自动切歌
     * cur // 调用next时正在播放的歌曲</pre>
     * @return {player}
     */

    Player.prototype.next = function(auto) {
      return ctrl.apply(this, ['next', auto]);
    };


    /**
     * 获取当前歌曲（根据业务逻辑和选链opts.fetch方法的具体实现可以是音频文件url，也可以是标识id，默认直接传入音频文件url即可）。
     * 如果之前没有主动执行过setCur，则认为播放列表的第一首歌是当前歌曲。
     * @return {String}
     */

    Player.prototype.getCur = function() {
      var cur, pl;
      pl = this.playlist;
      cur = pl.cur;
      if (!cur && this.getSongsNum()) {
        pl.cur = cur = pl.list[0];
      }
      return this._sid = '' + cur;
    };


    /**
     * 设置当前歌曲。
     * @param {String} sid 可以是音频文件url，也可以是音频文件id（如果是文件id，则要实现自己的opts.fetch方法，决定如何根据id获得相应音频的实际地址）。
     * @return {player}
     */

    Player.prototype.setCur = function(sid) {
      var pl;
      sid = '' + sid;
      pl = this.playlist;
      if (!sid && this.getSongsNum()) {
        sid = pl.list[0];
      }
      if (sid && this._sid !== sid) {
        pl.setCur(sid);
        this._sid = sid;
        this.stop();
      }
      this.trigger('player:setCur', sid);
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
     * 将音频资源添加到播放列表，会派发 <code>player:add</code> 事件。
     * @param {String|Array} sid 要添加的单曲资源或标识，为数组则代表批量添加。
     * @param {Boolean} unshift sid被添加到播放列表中的位置，默认是true，代表往数组前面添加，为flase时表示往数组后添加。
     * @return {player}
     */

    Player.prototype.add = function(sid, unshift) {
      if (unshift == null) {
        unshift = true;
      }
      if (sid) {
        this.playlist.add(sid, unshift);
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
      delete this._sid;
      this._retryTimes = 0;
      this.playlist.reset();
      this.engine.reset();
      this.trigger('player:reset');
      return this.stop();
    };


    /**
     * 销毁 <code>MuPlayer</code> 实例（解绑事件并销毁DOM）。
     * @return {player}
     */

    Player.prototype.destroy = function() {
      this.reset().off();
      this.engine.destroy();
      this.playlist.destroy();
      instance = null;
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
     * 设置当前播放资源的url。一般而言，这个方法是私有方法，供opts.fetch选链使用，客户端无需关心。
     * 但出于调试和灵活性的考虑，依然之暴露为公共方法。
     * @param {String} url
     * @return {player}
     */

    Player.prototype.setUrl = function(url) {
      if (!url) {
        return this;
      }
      this.stop().engine.setUrl(url);
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


    /**
     * 获取当前engineType。
     * @return {String} [FlashMP3Core|FlashMP3Core|AudioCore]
     */

    Player.prototype.getEngineType = function() {
      return this.engine.curEngine.engineType;
    };


    /**
     * 设置冻结（冻结后MuPlayer实例的set方法及切歌方法失效）
     * @param {Boolean} frozen 是否冻结。
     * @return {player}
     */

    Player.prototype.setFrozen = function(frozen) {
      this._frozen = !!frozen;
      return this;
    };

    Player.prototype._checkFrozen = function(fnames) {
      var i, len, name, results, self;
      self = this;
      results = [];
      for (i = 0, len = fnames.length; i < len; i++) {
        name = fnames[i];
        results.push(self[name] = utils.wrap(self[name], function() {
          var args, fn;
          fn = arguments[0], args = 2 <= arguments.length ? slice.call(arguments, 1) : [];
          if (!self._frozen) {
            fn.apply(self, args);
          }
          return self;
        }));
      }
      return results;
    };

    Player.prototype._startWaitingTimer = function() {
      this.waitingTimer.clear().after(this.opts.maxWaitingTime + " seconds", (function(_this) {
        return function() {
          return _this.engine.trigger(EVENTS.WAITING_TIMEOUT);
        };
      })(this)).start();
      return this;
    };

    Player.prototype._clearWaitingTimer = function() {
      this.waitingTimer.clear();
      return this;
    };

    return Player;

  })();
  Events.mixTo(Player);
  return Player;
});

