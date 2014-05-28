require 'coffee-script/register'
os = require './lib/os'

task 'build', 'Build all source code.', ->
	os.spawn 'node', ['kit/app_mgr.js', 'build']
