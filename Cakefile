require 'coffee-script/register'
os = require './lib/os'

task 'build', 'Build all source code.', ->
    os.spawn 'node', ['kit/app_mgr.js', 'build']

task 'doc', 'Build doc.', ->
    os.spawn 'node', ['kit/app_mgr.js', 'doc']

option '-p', '--port [port]', 'Which port to listen to. Example: cake -p 8080 server'
task 'server', 'Start test server.', (opts) ->
    os.spawn 'node', ['kit/app_mgr.js', 'server', opts.port or 8077]
