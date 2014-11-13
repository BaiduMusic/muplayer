process.env.NODE_ENV ?= 'development'

{
    kit,
    kit: { path, spawn, Promise }
} = require 'nobone'

join = path.join

app_mgr = join 'kit', 'app_mgr.coffee'
node_bin = join 'node_modules', '.bin'
karma_bin = join node_bin, 'karma'
coffee_bin = join node_bin, 'coffee'

option '-p', '--port [port]', 'Which port to listen to. Example: cake -p 8077 server'
option '-c', '--cli', 'Wheather to run test cases in CLI?'

task 'build', 'Build all source code.', ->
    spawn coffee_bin, [app_mgr, 'build']

task 'doc', 'Build doc.', ->
    spawn coffee_bin, [app_mgr, 'doc']

task 'server', 'Run dev server.', (opts) ->
    spawn coffee_bin, ['kit/app_mgr.coffee', 'server', opts.port or 8077]

task 'test', 'Run test runner.', (opts) ->
    args = opts.cli and [
        '--single-run',
        '--no-auto-watch',
        '--browsers', 'Chrome,Firefox,Safari,Opera,IE'
    ] or []
    spawn karma_bin, ['start', 'karma.conf.js'].concat(args)

task 'coffeelint', 'Lint all coffee files.', (opts) ->
    expand = kit.require 'glob-expand'
    coffeelint_bin = join node_bin, 'coffeelint'

    lint = (path) ->
        args = ['-f', 'coffeelint.json', path]
        if opts.quite
            args.unshift('-q')
        spawn coffeelint_bin, args

    Promise.resolve(expand(
        join('**', '*.coffee'),
        join('!node_modules', '**', '*.coffee'),
        join('!bower_components', '**', '*.coffee')
    )).then (file_list) ->
        Promise.map file_list, lint
