require 'colors'
Q = require 'q'
os = require '../lib/os'
_ = require 'lodash'

class Builder
	constructor: ->
		@src_path = 'src'
		@build_temp_path = 'build_temp'
		@require_temp_path = 'require_temp'
		@dist_path = 'dist'

	start: ->
		@start_time = Date.now()

		Q.fcall =>
			@update_build_dir()
		.then =>
			@compile_all_coffee()
		.then =>
			@combine_js()
		.then =>
			@compress_js()
		.then =>
			@build_as()
		.then =>
			@clean()
		.done ->
			console.log '>> Build done.'.yellow

	update_build_dir: ->
		# Delete old build first.
		Q.fcall =>
			os.remove @build_temp_path
		.then =>
			os.remove @dist_path
		.then =>
			from = 'src/js'
			os.copy(from, @build_temp_path + '/js').then ->
				console.log '>> Copy: '.cyan + from + ' -> '.green + @build_temp_path

	compile_all_coffee: ->
		coffee = require 'coffee-script'

		Q.fcall =>
			os.glob os.path.join(@build_temp_path, '**', '*.coffee')
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

	combine_js: (opts) ->
		console.log ">> Compile client js with requirejs ...".cyan

		requirejs = require 'requirejs'

		deferred = Q.defer()

		opts_pc = {
			appDir: @build_temp_path,
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

	compress_js: ->
		compress = (path) ->
			os.spawn 'node_modules/.bin/uglifyjs', [
				'-mt'
				'-o', path + '.min.js'
				path + '.js'
			]

		Q.all(
			[
				@dist_path + '/player'
				@dist_path + '/zepto-player'
			].map (el) ->
				compress el
		).then ->
			console.log ">> Compress js done.".cyan

	build_as: ->
		try
			flex_sdk = require 'flex-sdk'
		catch e
			console.log e
			return

		os.spawn(
			flex_sdk.bin.mxmlc, [
				'-optimize=true'
				'-show-actionscript-warnings=true'
				'-static-link-runtime-shared-libraries=true'
				'-o', "#{@dist_path}/muplayer_mp3.swf"
				@src_path + '/as/MP3Core.as'
			], (err, stdout, stderr) ->
				if err
					console.error err
				else
					console.log stdout
					console.log stderr
		).then ->
			console.log ">> Build AS done.".cyan

	clean: ->
		console.log ">> Clean temp folders...".cyan
		Q.all [
			os.remove @build_temp_path
			os.remove @require_temp_path
		]


module.exports = new Builder
