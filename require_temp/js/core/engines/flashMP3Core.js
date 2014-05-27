var __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  __slice = [].slice;

(function(root, factory) {
  if (typeof exports === 'object') {
    return module.exports = factory();
  } else if (typeof define === 'function' && define.amd) {
    return define(['muplayer/core/cfg', 'muplayer/core/utils', 'muplayer/lib/Timer', 'muplayer/core/engines/engineCore', 'muplayer/lib/jquery.swfobject'], factory);
  } else {
    return root._mu.FlashMP3Core = factory(_mu.cfg, _mu.utils, _mu.Timer, _mu.EngineCore);
  }
})(this, function(cfg, utils, Timer, EngineCore) {
  var ERRCODE, EVENTS, FlashMP3Core, STATES, STATESCODE, TYPES, timerResolution, _ref;
  _ref = cfg.engine, TYPES = _ref.TYPES, EVENTS = _ref.EVENTS, STATES = _ref.STATES, ERRCODE = _ref.ERRCODE;
  timerResolution = cfg.timerResolution;
  STATESCODE = {
    '-1': STATES.NOT_INIT,
    '1': STATES.PREBUFFER,
    '2': STATES.BUFFERING,
    '3': STATES.PLAYING,
    '4': STATES.PAUSE,
    '5': STATES.STOP,
    '6': STATES.END
  };
  FlashMP3Core = (function(_super) {
    __extends(FlashMP3Core, _super);

    FlashMP3Core.defaults = {
      swf: '../dist/swf/muplayer_mp3.swf',
      instanceName: 'MP3Core',
      flashVer: '9.0.0'
    };

    FlashMP3Core.prototype._supportedTypes = ['mp3'];

    FlashMP3Core.prototype.engineType = TYPES.FLASH_MP3;

    function FlashMP3Core(options) {
      var id, instanceName, opts;
      this.opts = opts = $.extend(FlashMP3Core.defaults, options);
      this._loaded = false;
      this._queue = [];
      this._needFlashReady(['play', 'pause', 'stop', 'setCurrentPosition', '_setUrl', '_setVolume', '_setMute']);
      this._unexceptionGet(['getCurrentPosition', 'getLoadedPercent', 'getTotalTime']);
      utils.namespace('engines')[opts.instanceName] = this;
      instanceName = '_mu.engines.' + opts.instanceName;
      id = 'muplayer_flashcore_' + setTimeout((function() {}), 0);
      this.flash = $.flash.create({
        swf: opts.swf,
        id: id,
        height: 1,
        width: 1,
        allowscriptaccess: 'always',
        wmode: 'transparent',
        expressInstaller: opts.expressInstaller || cfg.expressInstaller,
        flashvars: {
          _instanceName: instanceName,
          _buffertime: 5000
        }
      });
      opts.$el.append(this.flash);
      this._initEvents();
    }

    FlashMP3Core.prototype._test = function(trigger) {
      var opts;
      opts = this.opts;
      if (!$.flash.hasVersion(opts.flashVer)) {
        return false;
      }
      trigger && this.trigger(EVENTS.INITFAIL, this.engineType);
      return true;
    };

    FlashMP3Core.prototype._initEvents = function() {
      var triggerPosition, triggerProgress;
      this.progressTimer = new Timer(timerResolution);
      this.positionTimer = new Timer(timerResolution);
      triggerProgress = (function(_this) {
        return function() {
          var per;
          per = _this.getLoadedPercent();
          _this.trigger(EVENTS.PROGRESS, per);
          if (per === 1) {
            return _this.progressTimer.stop();
          }
        };
      })(this);
      triggerPosition = (function(_this) {
        return function() {
          return _this.trigger(EVENTS.POSITIONCHANGE, _this.getCurrentPosition());
        };
      })(this);
      this.progressTimer.every('200 ms', triggerProgress);
      this.positionTimer.every('200 ms', triggerPosition);
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

    FlashMP3Core.prototype._needFlashReady = function(fnames) {
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

    FlashMP3Core.prototype._unexceptionGet = function(fnames) {
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

    FlashMP3Core.prototype._pushQueue = function(fn, args) {
      return this._queue.push([fn, args]);
    };

    FlashMP3Core.prototype._fireQueue = function() {
      var args, fn, l, _ref1, _results;
      l = this._queue.length;
      _results = [];
      while (l--) {
        _ref1 = this._queue.shift(), fn = _ref1[0], args = _ref1[1];
        _results.push(fn.apply(this, args));
      }
      return _results;
    };

    FlashMP3Core.prototype.play = function() {
      this.flash.play();
      return this;
    };

    FlashMP3Core.prototype.pause = function() {
      this.flash.pause();
      return this;
    };

    FlashMP3Core.prototype.stop = function() {
      this.flash.stop();
      return this;
    };

    FlashMP3Core.prototype._setUrl = function(url) {
      return this.flash.load(url);
    };

    FlashMP3Core.prototype.setUrl = function(url) {
      if (url) {
        this._setUrl(url);
        (function(_this) {
          return (function() {
            var check, checker;
            checker = null;
            check = function(e) {
              if (e.newState === STATES.PLAY && e.oldState === STATES.PREBUFFER) {
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
      return FlashMP3Core.__super__.setUrl.call(this, url);
    };

    FlashMP3Core.prototype.getState = function(code) {
      return STATESCODE[code] || this._state;
    };

    FlashMP3Core.prototype._setVolume = function(volume) {
      return this.flash.setData('volume', volume);
    };

    FlashMP3Core.prototype.setVolume = function(volume) {
      if (!((0 <= volume && volume <= 100))) {
        this;
      }
      this._setVolume(volume);
      return FlashMP3Core.__super__.setVolume.call(this, volume);
    };

    FlashMP3Core.prototype._setMute = function(mute) {
      return this.flash.setData('mute', mute);
    };

    FlashMP3Core.prototype.setMute = function(mute) {
      mute = !!mute;
      this._setMute(mute);
      return FlashMP3Core.__super__.setMute.call(this, mute);
    };

    FlashMP3Core.prototype.setCurrentPosition = function(ms) {
      this.flash.play(ms);
      return this;
    };

    FlashMP3Core.prototype.getCurrentPosition = function() {
      return this.flash.getData('position');
    };

    FlashMP3Core.prototype.getLoadedPercent = function() {
      return this.flash.getData('loadedPct');
    };

    FlashMP3Core.prototype.getTotalTime = function() {
      return this.flash.getData('length');
    };

    FlashMP3Core.prototype._swfOnLoad = function() {
      this._loaded = true;
      return setTimeout((function(_this) {
        return function() {
          return _this._fireQueue();
        };
      })(this), 0);
    };

    FlashMP3Core.prototype._swfOnStateChange = function(code) {
      return this.setState(this.getState(code));
    };

    FlashMP3Core.prototype._swfOnErr = function(e) {
      return typeof console !== "undefined" && console !== null ? console.error(e) : void 0;
    };

    return FlashMP3Core;

  })(EngineCore);
  return FlashMP3Core;
});
