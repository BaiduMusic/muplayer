var __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  __slice = [].slice;

(function(root, factory) {
  if (typeof exports === 'object') {
    return module.exports = factory();
  } else if (typeof define === 'function' && define.amd) {
    return define(['muplayer/core/cfg', 'muplayer/core/utils', 'muplayer/lib/Timer', 'muplayer/core/engines/engineCore', 'muplayer/lib/jquery.swfobject'], factory);
  } else {
    return root._mu.FlashCore = factory(_mu.cfg, _mu.utils, _mu.Timer, _mu.EngineCore);
  }
})(this, function(cfg, utils, Timer, EngineCore) {
  var ERRCODE, EVENTS, FlashCore, STATES, STATESCODE, TYPES, timerResolution, _ref;
  _ref = cfg.engine, TYPES = _ref.TYPES, EVENTS = _ref.EVENTS, STATES = _ref.STATES, ERRCODE = _ref.ERRCODE;
  timerResolution = cfg.timerResolution;
  STATESCODE = {
    '-2': STATES.INIT,
    '-1': STATES.READY,
    '0': STATES.STOP,
    '1': STATES.PLAY,
    '2': STATES.PAUSE,
    '3': STATES.END,
    '4': STATES.BUFFERING,
    '5': STATES.PREBUFFER,
    '6': STATES.ERROR
  };
  FlashCore = (function(_super) {
    __extends(FlashCore, _super);

    FlashCore.defaults = {
      swf: '/swf/fmp.swf',
      instanceName: 'muplayer',
      flashVer: '9.0.0'
    };

    FlashCore.prototype._supportedTypes = ['mp3'];

    FlashCore.prototype.engineType = TYPES.FLASH;

    function FlashCore(options) {
      var id, instanceName, opts;
      this.opts = opts = $.extend(FlashCore.defaults, options);
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
          _buffertime: 2000
        }
      });
      opts.$el.append(this.flash);
      this._initEvents();
    }

    FlashCore.prototype._test = function(trigger) {
      var opts;
      opts = this.opts;
      if (!$.flash.hasVersion(opts.flashVer)) {
        return false;
      }
      trigger && this.trigger(EVENTS.INITFAIL, this.engineType);
      return true;
    };

    FlashCore.prototype._initEvents = function() {
      var triggerPosition, triggerProgress,
        _this = this;
      this.progressTimer = new Timer(timerResolution);
      this.positionTimer = new Timer(timerResolution);
      triggerProgress = function() {
        var per;
        per = _this.getLoadedPercent();
        _this.trigger(EVENTS.PROGRESS, per);
        if (per === 1) {
          return _this.progressTimer.stop();
        }
      };
      triggerPosition = function() {
        return _this.trigger(EVENTS.POSITIONCHANGE, _this.getCurrentPosition());
      };
      this.progressTimer.every('200 ms', triggerProgress);
      this.positionTimer.every('200 ms', triggerPosition);
      return this.on(EVENTS.STATECHANGE, function(e) {
        var st;
        st = e.newState;
        switch (st) {
          case STATES.PREBUFFER:
          case STATES.PLAY:
            _this.progressTimer.start();
            break;
          case STATES.PAUSE:
          case STATES.STOP:
            _this.progressTimer.stop();
            break;
          case STATES.READY:
          case STATES.END:
            _this.progressTimer.reset();
        }
        switch (st) {
          case STATES.PLAY:
            return _this.positionTimer.start();
          case STATES.PAUSE:
          case STATES.STOP:
            _this.positionTimer.stop();
            return triggerPosition();
          case STATES.READY:
          case STATES.END:
            return _this.positionTimer.reset();
        }
      });
    };

    FlashCore.prototype._needFlashReady = function(fnames) {
      var name, _i, _len, _results,
        _this = this;
      _results = [];
      for (_i = 0, _len = fnames.length; _i < _len; _i++) {
        name = fnames[_i];
        _results.push(this[name] = utils.wrap(this[name], function() {
          var args, fn;
          fn = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
          if (_this._loaded) {
            fn.apply(_this, args);
          } else {
            _this._pushQueue(fn, args);
          }
          return _this;
        }));
      }
      return _results;
    };

    FlashCore.prototype._unexceptionGet = function(fnames) {
      var name, _i, _len, _results,
        _this = this;
      _results = [];
      for (_i = 0, _len = fnames.length; _i < _len; _i++) {
        name = fnames[_i];
        _results.push(this[name] = utils.wrap(this[name], function() {
          var args, fn;
          fn = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
          try {
            return fn.apply(_this, args);
          } catch (_error) {
            return 0;
          }
        }));
      }
      return _results;
    };

    FlashCore.prototype._pushQueue = function(fn, args) {
      return this._queue.push([fn, args]);
    };

    FlashCore.prototype._fireQueue = function() {
      var args, fn, l, _ref1, _results;
      l = this._queue.length;
      _results = [];
      while (l--) {
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
      var _this = this;
      this._setUrl(url);
      (function() {
        var check, checker;
        checker = null;
        check = function(e) {
          if (e.newState === STATES.PLAY && e.oldState === STATES.PREBUFFER) {
            return checker = setTimeout(function() {
              _this.off(EVENTS.STATECHANGE, check);
              if (_this.getCurrentPosition() < 100) {
                _this.setState(STATES.ERROR);
                return _this.trigger(EVENTS.ERROR, ERRCODE.MEDIA_ERR_SRC_NOT_SUPPORTED);
              }
            }, 2000);
          } else {
            return clearTimeout(checker);
          }
        };
        return _this.off(EVENTS.STATECHANGE, check).on(EVENTS.STATECHANGE, check);
      })();
      return FlashCore.__super__.setUrl.call(this, url);
    };

    FlashCore.prototype.getState = function(code) {
      return STATESCODE[code] || this._status;
    };

    FlashCore.prototype._setVolume = function(volume) {
      return this.flash.setData('volume', volume);
    };

    FlashCore.prototype.setVolume = function(volume) {
      if (!((0 <= volume && volume <= 100))) {
        this;
      }
      this._setVolume(volume);
      return FlashCore.__super__.setVolume.call(this, volume);
    };

    FlashCore.prototype._setMute = function(mute) {
      return this.flash.setData('mute', mute);
    };

    FlashCore.prototype.setMute = function(mute) {
      mute = !!mute;
      this._setMute(mute);
      return FlashCore.__super__.setMute.call(this, mute);
    };

    FlashCore.prototype.setCurrentPosition = function(ms) {
      this.flash.f_play(ms);
      return this;
    };

    FlashCore.prototype.getCurrentPosition = function() {
      return this.flash.getData('currentPosition');
    };

    FlashCore.prototype.getLoadedPercent = function() {
      return this.flash.getData('loadedPct');
    };

    FlashCore.prototype.getTotalTime = function() {
      return this.flash.getData('length');
    };

    FlashCore.prototype._swfOnLoad = function() {
      var _this = this;
      this.setState(STATES.READY);
      this.trigger(EVENTS.INIT, this.engineType);
      this._loaded = true;
      return setTimeout(function() {
        return _this._fireQueue();
      }, 0);
    };

    FlashCore.prototype._swfOnStateChange = function(code) {
      return this.setState(this.getState(code));
    };

    return FlashCore;

  })(EngineCore);
  return FlashCore;
});
