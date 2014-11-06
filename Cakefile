process.env.NODE_ENV ?= 'development'

{
    kit: { path, spawn }
} = require 'nobone'

join = path.join

app_mgr = join 'kit', 'app_mgr.coffee'
node_bin = join 'node_modules', '.bin'
karma_bin = join node_bin, 'karma'
coffee_bin = join node_bin, 'coffee'

option '-p', '--port [port]', 'Which port to listen to. Example: cake -p 8077 server'

task 'build', 'Build all source code.', ->
    spawn coffee_bin, [app_mgr, 'build']

task 'doc', 'Build doc.', ->
    spawn coffee_bin, [app_mgr, 'doc']

task 'server', 'Run a dev server.', (opts) ->
    spawn coffee_bin, ['kit/app_mgr.coffee', 'server', opts.port or 8077]

task 'test', 'Run a test server.', (opts) ->
    spawn karma_bin, ['start', 'karma.conf.js']
