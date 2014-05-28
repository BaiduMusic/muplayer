_ = require 'lodash'
Q = require 'q'
fs = require 'fs-extra'
graceful = require 'graceful-fs'
child_process = require 'child_process'
glob = require 'glob'
which = require 'which'

prompt = require 'prompt'
prompt.message = '>> '
prompt.delimiter = ''

os =

	spawn: (cmd, args = [], options = {}) ->
		deferred = Q.defer()

		opts = _.defaults options, { stdio: 'inherit' }

		# The Windows use something like `coffee.cmd` in `node_moduels/.bin` folder.
		if process.platform == 'win32'
			win_cmd = cmd + '.cmd'
			if fs.existsSync win_cmd
				cmd = win_cmd
			else if not fs.existsSync cmd
				cmd = which.sync(cmd)

		ps = child_process.spawn cmd, args, opts

		ps.on 'error', (data) ->
			deferred.reject data

		ps.on 'close', (code) ->
			if code == 0
				deferred.resolve code
			else
				deferred.reject code

		return deferred.promise

	env_mode: (mode) ->
		{
			env: _.extend(
				process.env, { NODE_ENV: mode }
			)
		}

	path: require 'path'

	# Use graceful-fs to prevent os max open file limit error.
	readFile: Q.denodeify graceful.readFile
	outputFile: Q.denodeify fs.outputFile
	copy: Q.denodeify fs.copy
	symlink: Q.denodeify fs.symlink
	exists: Q.denodeify fs.exists
	rename: Q.denodeify fs.rename
	remove: Q.denodeify fs.remove
	chmod: Q.denodeify fs.chmod
	glob: Q.denodeify glob
	prompt_get: Q.denodeify prompt.get


module.exports = os