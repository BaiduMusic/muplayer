// @license
// Baidu Music Player: 0.9.2
// -------------------------
// (c) 2014 FE Team of Baidu Music
// Can be freely distributed under the BSD license.
(function(root, factory) {
  if (typeof exports === 'object') {
    return module.exports = factory();
  } else if (typeof define === 'function' && define.amd) {
    return define('muplayer/plugin/lrc',factory);
  } else {
    return root._mu.Lrc = factory();
  }
})(this, function() {
  var Lrc, offsetReg, splitReg, time2ms, timeReg, txtReg;
  splitReg = /\n|\r/;
  txtReg = /\[[\s\S]*?\]/;
  timeReg = /\[\d{2,}:\d{2}(?:[\.|:]\d{2,5})?\]/g;
  offsetReg = /\[offset:[+|\-]?\d+?(?=\])/;
  time2ms = function(time) {
    var m, ms, s, t;
    t = time.split(':');
    m = t[0];
    if (t.length === 3) {
      s = t[1];
      ms = t[2];
    } else {
      t = t[1].split('.');
      s = t[0];
      ms = t[1];
    }
    return ~~m * 60 * 1000 + ~~s * 1000 + ~~ms;
  };
  Lrc = (function() {
    Lrc.prototype.defaults = {
      lrc: '',
      el: '<div></div>',
      ul: '<ul></ul>',
      itemSelector: 'li',
      tmpl: _.template('<li lang="<%- time %>"><%= txt && _.escape(txt) || "&nbsp;" %></li>'),
      cls: 'ui-lrc',
      duration: 500,
      offset: 0
    };

    function Lrc(options) {
      var opts;
      this.opts = opts = $.extend({}, this.defaults, options);
      this.$el = $(opts.el).addClass(opts.cls);
      this.$ul = $(opts.ul).appendTo(this.$el);
      this.parse();
      this.render();
    }

    Lrc.prototype.render = function() {
      var $el, $ul, opts;
      $el = this.$el, $ul = this.$ul, opts = this.opts;
      return console.log(this._parsed);
    };

    Lrc.prototype.isLrc = function(lrc) {
      return timeReg.test(lrc);
    };

    Lrc.prototype.setStatus = function(st) {
      this.status = st;
      return this.$el.addClass(st);
    };

    Lrc.prototype.parseLrc = function(lrc) {
      var item, items, line, match, offset, r, time, txt, _i, _j, _len, _len1, _ref;
      r = [];
      offset = 0;
      if (match = lrc.match(offsetReg)) {
        offset = ~~match[0].slice(8);
      }
      _ref = lrc.split(splitReg);
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        line = _ref[_i];
        items = line.match(timeReg);
        if ($.isArray(items)) {
          txt = $.trim(line.replace(items.join(''), ''));
        }
        for (_j = 0, _len1 = items.length; _j < _len1; _j++) {
          item = items[_j];
          time = time2ms(item.slice(1, -1)) + offset;
          r.push([time, txt]);
        }
      }
      if (r.length) {
        this._parsed = r.sort(function(a, b) {
          return a[0] - b[0];
        });
        return this.setStatus('lrc');
      } else {
        return this.setStatus('no-lrc');
      }
    };

    Lrc.prototype.parseTxt = function(txt) {
      var line, lines, r, _i, _len;
      r = [];
      lines = txt.replace(txtReg, '').split(splitReg);
      for (_i = 0, _len = lines.length; _i < _len; _i++) {
        line = lines[_i];
        line = $.trim(line);
        if (line) {
          r.push([-1, line]);
        }
      }
      if (r.length) {
        this._parsed = r;
        return this.setStatus('txt-lrc');
      } else {
        return this.setStatus('no-lrc');
      }
    };

    Lrc.prototype.parse = function() {
      var lrc;
      lrc = this.opts.lrc;
      if (!_.isString(lrc) || !(lrc = $.trim(lrc))) {
        return this.setStatus('no-lrc');
      }
      if (this.isLrc(lrc)) {
        return this.parseLrc(lrc);
      } else {
        return this.parseTxt(lrc);
      }
    };

    Lrc.prototype.findLine = function(ms) {
      var getTime, head, mid, parsed, tail;
      parsed = this._parsed;
      if (!parsed || !parsed.length) {
        return -1;
      }
      head = 0;
      tail = parsed.length;
      mid = Math.floor(floor / 2);
      getTime = function(pos) {
        var item;
        item = parsed[pos];
        return item && item[0] || Number.MAX_VALUE;
      };
      if (ms < getTime(0)) {
        return -1;
      }
      while (true) {
        if (ms < getTime(mid)) {
          tail = mid - 1;
        } else {
          head = mid + 1;
        }
        mid = Math.floor((head + tail) / 2);
        if (ms >= getTime(mid) && ms < getTime(mid + 1)) {
          break;
        }
      }
      return mid;
    };

    return Lrc;

  })();
  return Lrc;
});

