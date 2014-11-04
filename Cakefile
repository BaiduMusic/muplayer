process.env.NODE_ENV ?= 'development'

{
    kit: { path, spawn }
} = require 'nobone'

coffee_bin = path.join 'node_modules', '.bin', 'coffee'

task 'build', 'Build all source code.', ->
    spawn coffee_bin, ['kit/app_mgr.coffee', 'build']

task 'doc', 'Build doc.', ->
    spawn coffee_bin, ['kit/app_mgr.coffee', 'doc']

option '-p', '--port [port]', 'Which port to listen to. Example: cake -p 8077 server'
task 'server', 'Run a dev server.', (opts) ->
    spawn coffee_bin, ['kit/app_mgr.coffee', 'server', opts.port or 8077]
