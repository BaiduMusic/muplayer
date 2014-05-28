require 'coffee-script/register'
os = require './lib/os'

task 'build', 'Build all source code.', ->
	os.spawn 'node', ['kit/app_mgr.js', 'build']

task 'doc', 'Build doc.', ->
	os.spawn 'node', ['kit/app_mgr.js', 'doc']

task 'server', 'Start test server.', ->
	os.spawn 'node', ['kit/app_mgr.js', 'server']
