(function (root, factory) {
    if (typeof exports === 'object') {
        module.exports = factory();
    } else if (typeof define === 'function' && define.amd) {
        define(factory);
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
