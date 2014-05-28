require 'coffee-script/register'
os = require './lib/os'

task 'setup', 'Build all source code.', ->
	os.spawn 'node', ['kit/app_mgr.js', 'setup']

task 'build', 'Build all source code.', ->
	os.spawn 'node', ['kit/app_mgr.js', 'build']
