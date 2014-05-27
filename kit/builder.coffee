require 'colors'
Q = require 'q'
os = require '../lib/os'
_ = require 'lodash'

class Builder
	constructor: ->
		@init_variables()

	init_variables: ->
		@build_path = 'build_temp'
		@require_temp_path = 'require_temp'
		@dist_path = 'dist'

	start: ->
		@start_time = Date.now()

		Q.fcall =>
			@update_build_dir()
		.then =>
			@compile_all_coffee()
		.then =>
			@compress_client_js()
		.done ->
			console.log 'ok'

	update_build_dir: ->
		# Delete old build first.
		Q.fcall =>
			os.remove @build_path
		.then =>
			os.remove @dist_path
		.then =>
			from = 'src/js'
			os.copy(from, @build_path + '/js').then ->
				console.log '>> Copy: '.cyan + from + ' -> '.green + @build_path

	compile_all_coffee: ->
		coffee = require 'coffee-script'

		Q.fcall =>
			os.glob os.path.join(@build_path, '**', '*.coffee')
		.then (coffee_list) =>
			Q.all coffee_list.map (path) =>
				js_path = path.replace(/(\.coffee)$/, '') + '.js'

				Q.fcall =>
					os.readFile(path, 'utf8')
				.then (str) ->
					try
						return coffee.compile(str, { bare: true })
					catch e
						console.log ">> Error: #{path} \n#{e}".red
						throw e
				.then (code) =>
					Q.fcall =>
						os.outputFile(js_path, code)
					.then =>
						os.remove(path)
					.then ->
						console.log '>> Compiled: '.cyan + path

	compress_client_js: (opts) ->
		console.log ">> Compile client js with requirejs ...".cyan

		requirejs = require 'requirejs'

		deferred = Q.defer()

		opts_pc = {
			appDir: @build_path,
			baseUrl: 'js/',
			dir: @require_temp_path,

			optimize: 'none',
			optimizeCss: 'standard',
			modules: [
				{
					name: 'muplayer/player'
				}
			],
			fileExclusionRegExp: /^\./,
			removeCombined: true,
			wrap: {
				startFile: 'src/license.txt'
			},
			pragmas: {
				FlashCoreExclude: false
			},
			# HACK: 为了映射muplayer这个namespace
			paths: {
				'muplayer': '.'
			}
		}

		# PC
		requirejs.optimize(opts_pc, (buildResponse) =>
			Q.fcall =>
				os.copy @require_temp_path + '/js/player.js', @dist_path + '/player.js'
			.then =>
				opts_webapp = _.cloneDeep opts_pc
				opts_webapp.pragmas.FlashCoreExclude = true

				# Webapp
				requirejs.optimize(opts_webapp, (buildResponse) =>
					Q.fcall =>
						os.copy @require_temp_path + '/js/player.js', @dist_path + '/zepto-player.js'
					.then ->
						console.log ">> Compile client js done.".cyan
						deferred.resolve buildResponse
				, (err) ->
					deferred.reject err
				)

		, (err) ->
			deferred.reject err
		)


		return deferred.promise

module.exports = new Builder
