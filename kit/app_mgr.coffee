#!node_modules/.bin/coffee

require 'coffee-script/register'
require 'colors'
os = require '../lib/os'
Q = require 'q'

coffee_bin = os.path.resolve os.path.join('node_modules','.bin', 'coffee')

main = ->
	switch process.argv[2]
		when 'setup'
			setup = require './setup'
			setup.start()

		when 'build'
			builder = require './builder'
			builder.start()

main()
