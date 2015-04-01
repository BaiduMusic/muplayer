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
      el: '',
      ul: '<ul></ul>',
      itemTmpl: _.template('<li class="<%- cls %>" lang="<%- time %>"><%= txt && _.escape(txt) || "&nbsp;" %></li>'),
      cls: 'muui-lrc',
      itemCls: 'muui-lrc-item',
      scrollingCls: 'muui-lrc-scrolling',
      duration: 500,
      offset: 0
    };

    function Lrc(options) {
      var opts;
      this.opts = opts = $.extend({}, this.defaults, options);
      if (!opts.el) {
        throw new Error('el cannot be empty.');
      }
      this.$el = $(opts.el).addClass(opts.cls);
      this.$ul = $(opts.ul).appendTo(this.$el);
      this.create(opts.lrc);
    }

    Lrc.prototype.create = function(lrc) {
      delete this._curLine;
      this.lrc = lrc;
      this.parse();
      return this.render();
    };

    Lrc.prototype.render = function() {
      var $el, $ul, i, item, itemCls, itemTmpl, len, ref, ref1, scrollingCls;
      $el = this.$el, $ul = this.$ul, (ref = this.opts, itemTmpl = ref.itemTmpl, scrollingCls = ref.scrollingCls, itemCls = ref.itemCls);
      ref1 = this._parsed;
      for (i = 0, len = ref1.length; i < len; i++) {
        item = ref1[i];
        $ul.append(itemTmpl({
          cls: itemsCls,
          time: item[0],
          txt: item[1]
        }));
      }
      $el.on('scroll', function() {
        $el.addClass(scrollingCls);
        return _.debounce(function() {
          return $el.removeClass(scrollingCls);
        }, 1000);
      }).html($ul);
      return this.$item = $el.find("." + itemsCls);
    };

    Lrc.prototype.scrollTo = _.throttle(function(ms) {
      var $el, $item, duration, line, offset, opts, ref, scrollingCls, top;
      ms = ~~ms;
      if (!ms || this.getState() !== 'lrc') {
        return;
      }
      $el = this.$el, $item = this.$item, opts = this.opts, (ref = this.opts, scrollingCls = ref.scrollingCls, offset = ref.offset, duration = ref.duration);
      if ($el.hasClass(scrollingCls)) {
        return;
      }
      $item.removeClass('on');
      line = this.findLine(ms);
      if (line === -1) {
        return $el.scrollTop(0);
      } else if (line === this._curLine) {
        return;
      }
      this._curLine = line;
      top = $item.eq(line).addClass('on').position().top - $el.height() / 2 + offset;
      if (top < 0) {
        top = 0;
      }
      return $el.stop(true).animate({
        scrollTop: top
      }, duration);
    }, 500);

    Lrc.prototype.isLrc = function(lrc) {
      return timeReg.test(lrc);
    };

    Lrc.prototype.setState = function(st) {
      this._state = st;
      return this.$el.addClass(st);
    };

    Lrc.prototype.getState = function() {
      return this._state;
    };

    Lrc.prototype.parseLrc = function(lrc) {
      var i, item, items, j, len, len1, line, match, offset, r, ref, time, txt;
      r = [];
      offset = 0;
      if (match = lrc.match(offsetReg)) {
        offset = ~~match[0].slice(8);
      }
      ref = lrc.split(splitReg);
      for (i = 0, len = ref.length; i < len; i++) {
        line = ref[i];
        items = line.match(timeReg);
        if ($.isArray(items)) {
          txt = $.trim(line.replace(items.join(''), ''));
        }
        for (j = 0, len1 = items.length; j < len1; j++) {
          item = items[j];
          time = time2ms(item.slice(1, -1)) + offset;
          r.push([time, txt]);
        }
      }
      if (r.length) {
        this._parsed = r.sort(function(a, b) {
          return a[0] - b[0];
        });
        return this.setState('lrc');
      } else {
        return this.setState('no-lrc');
      }
    };

    Lrc.prototype.parseTxt = function(txt) {
      var i, len, line, lines, r;
      r = [];
      lines = txt.replace(txtReg, '').split(splitReg);
      for (i = 0, len = lines.length; i < len; i++) {
        line = lines[i];
        line = $.trim(line);
        if (line) {
          r.push([-1, line]);
        }
      }
      if (r.length) {
        this._parsed = r;
        return this.setState('txt-lrc');
      } else {
        return this.setState('no-lrc');
      }
    };

    Lrc.prototype.parse = function() {
      var lrc;
      lrc = this.lrc;
      if (!_.isString(lrc) || !(lrc = $.trim(lrc))) {
        return this.setState('no-lrc');
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

