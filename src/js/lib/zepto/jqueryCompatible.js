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
        } else if (isFunction(op)) {
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
