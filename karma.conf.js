// Karma configuration
// Generated on Thu Nov 06 2014 15:24:31 GMT+0800 (CST)

module.exports = function(config) {
  config.set({

    // base path that will be used to resolve all patterns (eg. files, exclude)
    basePath: '',


    // frameworks to use
    // available frameworks: https://npmjs.org/browse/keyword/karma-adapter
    frameworks: ['mocha'],


    client: {
      captureConsole: true,
      mocha: {
        reporter: 'html', // change Karma's debug.html to the mocha web reporter
        ui: 'tdd'
      }
    },


    // list of files / patterns to load in the browser
    files: [
      {
        pattern: 'dist/*.swf',
        included: false
      },
      {
        pattern: 'doc/mp3/*',
        included: false
      },
      'bower_components/jquery/jquery.js',
      'bower_components/chai/chai.js',
      'bower_components/mocha/mocha.js',
      'bower_components/mocha/mocha.css',
      'dist/player.js',
      'test/setup.coffee',
      'test/utils.coffee',
      'test/player.coffee',
      'test/engine.coffee',
      'test/playlist.coffee'
    ],


    // list of files to exclude
    exclude: [
    ],


    // preprocess matching files before serving them to the browser
    // available preprocessors: https://npmjs.org/browse/keyword/karma-preprocessor
    preprocessors: {
        '**/*.coffee': 'coffee'
    },


    // test results reporter to use
    // possible values: 'dots', 'progress'
    // available reporters: https://npmjs.org/browse/keyword/karma-reporter
    reporters: ['mocha'],


    // web server port
    port: 9876,


    // enable / disable colors in the output (reporters and logs)
    colors: true,


    // level of logging
    // possible values: config.LOG_DISABLE || config.LOG_ERROR || config.LOG_WARN || config.LOG_INFO || config.LOG_DEBUG
    logLevel: config.LOG_INFO,


    // enable / disable watching file and executing tests whenever any file changes
    autoWatch: true,


    // start these browsers
    // available browser launchers: https://npmjs.org/browse/keyword/karma-launcher
    browsers: ['Chrome'],


    // Continuous Integration mode
    // if true, Karma captures browsers, runs the tests and exits
    singleRun: false
  });
};
