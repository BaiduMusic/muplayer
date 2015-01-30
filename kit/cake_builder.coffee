{
    kit,
    kit: { path, spawn, Promise }
} = require 'nobone'

join = path.join

app_mgr = join 'kit', 'app_mgr.coffee'

options = [
    ['-p', '--port [port]', 'Which port to listen to. Example: cake -p 8077 server']
    ['-q', '--quite', 'Running lint script at quite mode results in only printing errors. Example: cake -q coffeelint']
    ['-r', '--rebuild', 'Wheather to rebuild src and doc files before run dev server?']
    ['-c', '--cli', 'Wheather to run test cases in CLI?']
]

tasks = [
    [
        'setup'
        'Setup project.'
        ->
            setup = require './setup'
            setup.start()
    ]
    [
        'build'
        'Build all source code.'
        ->
            spawn 'coffee', [app_mgr, 'build']
    ]
    [
        'doc'
        'Build doc.'
        ->
            spawn 'coffee', [app_mgr, 'doc']
    ]
    [
        'server'
        'Run dev server.'
        (opts) ->
            run = ->
                spawn 'coffee', [app_mgr, 'server', opts.port or 8077]

            if opts.rebuild
                invoke 'build'
                .then ->
                    invoke 'doc'
                .then ->
                    run()
            else
                run()
    ]
    [
        'test'
        'Run test runner.'
        (opts) ->
            args = opts.cli and [
                '--single-run',
                '--no-auto-watch',
                # Travis supports running a real browser (Firefox) with a virtual screen.
                '--browsers', 'Firefox'
            ] or []
            spawn 'karma', ['start', 'karma.conf.js'].concat(args)
    ]
    [
        'coffeelint'
        'Lint all coffee files.'
        (opts) ->
            expand = kit.require 'glob-expand'

            lint = (path) ->
                args = ['-f', 'coffeelint.json', path]
                if opts.quite
                    args.unshift('-q')
                spawn 'coffeelint', args

            Promise.resolve(expand(
                join('**', '*.coffee'),
                join('!lib', '**', '*.coffee'),
                join('!node_modules', '**', '*.coffee'),
                join('!bower_components', '**', '*.coffee')
            )).then (file_list) ->
                Promise.map file_list, lint
    ]
]

module.exports =
    options: options

    tasks: tasks

    build: (type, args) ->
        global[type].apply(null, args)

    build_all: ->
        for option in @options
            @build('option', option)

        for task in @tasks
            @build('task', task)
