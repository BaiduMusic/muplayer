nobone = require 'nobone'

{
    kit,
    kit: { _, log, remove, spawn, Promise }
} = nobone

class NofileBuilder
    constructor: (options) ->
        defaults =
            dirname: __dirname

            options:
                '-p, --port <8077>': ['Which port to listen to. Example: no -p 8077 server', 8077]
                'r, --rebuild': ['Wheather to rebuild src and doc files before run dev server?']
                '-c, --cli': ['Wheather to run test cases in CLI?']

            tasks:
                'setup': [
                    'Setup project.',
                    =>
                        setup = kit.require './kit/setup', @opts.dirname
                        setup()
                ]

                'build': [
                    'Build all source code.', @_build
                ]

                'doc': [
                    'Build doc.', @_build_doc
                ]

                'server': [
                    'Run dev server.',
                    (opts) =>
                        self = @
                        { service, renderer } = nobone()

                        run = ->
                            service.use '/', renderer.static('doc')
                            service.listen opts.port, ->
                                log '>> Server start at port: '.cyan + opts.port

                        if opts.rebuild
                            @_build()
                            .then ->
                                self._build_doc()
                            .then ->
                                run()
                        else
                            run()
                ]

                'test': [
                    'Run test runner.',
                    (opts) =>
                        if opts.cli
                            @_build()
                            .then ->
                                spawn 'karma', ['start', 'karma.conf.js'].concat([
                                    '--single-run',
                                    '--no-auto-watch',
                                    # Travis supports running a real browser (Firefox) with a virtual screen.
                                    '--browsers', 'Firefox'
                                ])
                        else
                            spawn 'karma', ['start', 'karma.conf.js']
                ]

                'coffeelint': [
                    'Lint all coffee files.',
                    (opts) ->
                        kit.require 'drives'

                        kit.warp ['{src,kit,test}/**/*.coffee', '*.coffee']
                        .load kit.drives.auto 'lint'
                        .load (f) ->
                            f.set null
                        .run()
                ]

        @opts = _.extend(defaults, options)

    build: (handler, handler_type, names) ->
        return unless handler_type in ['option', 'task']
        rs = @opts["#{handler_type}s"]
        for name in names
            args = rs[name]
            if args
                args.unshift(name)
                handler.apply(null, args)

    _build: =>
        Builder = kit.require './kit/builder', @opts.dirname
        builder = new Builder()
        builder.start()

    _build_doc: =>
        remove('doc', {
            isFollowLink: false
        }).then ->
            Promise.all([
                spawn('compass', [
                    'compile'
                    '--sass-dir', 'src/css'
                    '--css-dir', 'doc/css'
                    '--no-line-comments'
                ])
                spawn('doxx', [
                    '-d'
                    '-R', 'README.md'
                    '-t', 'MuPlayer 『百度音乐播放内核』'
                    '-s', 'dist'
                    '-T', 'doc_temp'
                    '--template', 'src/doc/base.jade'
                ])
            ])
        .then ->
            copy_to = (from, to) ->
                kit.copy 'doc_temp/' + from, 'doc/' + to

            Promise.all([
                copy_to 'player.js.html', 'api.html'
                copy_to 'index.html', 'index.html'
            ])
        .then ->
            remove 'doc_temp'
        .then ->
            symlink_to = (from, to, type = 'dir') ->
                kit.symlink '../' + from, 'doc/' + to, type

            Promise.all [
                symlink_to 'dist', 'dist'
                symlink_to 'bower_components', 'bower_components'
                symlink_to 'src/doc/img', 'img'
                symlink_to 'src/doc/mp3', 'mp3'
                symlink_to 'src/doc/js', 'js'
                symlink_to 'src/img/favicon.ico', 'favicon.ico', 'file'
                kit.glob 'src/doc/*.html'
                .then (paths) ->
                    for p in paths
                        to = 'doc/' + kit.path.basename p
                        log '>> Link: '.cyan + p + ' -> '.cyan + to
                        kit.symlink '../' + p, to
            ]

module.exports = NofileBuilder
