process.env.NODE_ENV ?= 'development'

{
    kit: { path, spawn }
} = require 'nobone'

app_mgr = path.join 'kit', 'app_mgr.coffee'
coffee_bin = path.join 'node_modules', '.bin', 'coffee'

task 'build', 'Build all source code.', ->
    spawn coffee_bin, [app_mgr, 'build']

task 'doc', 'Build doc.', ->
    spawn coffee_bin, [app_mgr, 'doc']

option '-p', '--port [port]', 'Which port to listen to. Example: cake -p 8077 server'
task 'server', 'Run a dev server.', (opts) ->
    spawn coffee_bin, ['kit/app_mgr.coffee', 'server', opts.port or 8077]
