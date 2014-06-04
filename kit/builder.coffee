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
        @lib_path = 'lib'

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
            @add_license()
        .then =>
            @complie_as()
        .then =>
            @clean()
        .done ->
            console.log '>> Build done.'.yellow

    update_build_dir: ->
        # Delete old build first.
        Q.fcall =>
            os.remove @build_temp_path
        .then =>
            from = 'src/js'
            os.copy(from, @build_temp_path + '/js').then =>
                console.log '>> Copy: '.cyan + from + ' -> '.green + @build_temp_path
        .then =>
            os.copy @lib_path + '/expressInstall.swf', @dist_path + '/expressInstall.swf'

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
            pragmas: {
                FlashCoreExclude: false
            },
            # 为映射muplayer这个namespace
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

    add_license: ->
        conf = require '../bower'
        info = """
            // @license
            // Baidu Music Player: #{conf.version}
            // -------------------------
            // (c) 2014 FE Team of Baidu Music
            // Can be freely distributed under the BSD license.\n
        """

        Q.fcall =>
            os.glob @dist_path + '/*.js'
        .then (paths) ->
            Q.all paths.map (el) ->
                console.log ">> License info added: ".cyan + el
                os.readFile(el, 'utf8')
                .then (str) ->
                    os.outputFile el, info + str

    complie_as: ->
        try
            flex_sdk = require 'flex-sdk'
        catch e
            console.log ">> Warn: ".yellow + e.message
            return

        compile = (src, dist) =>
            bin_name = 'muplayer_mp3.swf'

            os.spawn flex_sdk.bin.mxmlc, [
                '-optimize=true'
                '-show-actionscript-warnings=true'
                '-static-link-runtime-shared-libraries=true'
                '-o', "#{@dist_path}/#{dist}.swf"
                "#{@src_path}/as/#{src}.as"
            ], (err, stdout, stderr) ->
                if err
                    console.error err
                else
                    console.log stdout
                    console.log stderr

        Q.all([
            compile 'MP3Core', 'muplayer_mp3'
            compile 'MP4Core', 'muplayer_mp4'
        ]).then ->
            console.log ">> Build AS done.".cyan

    clean: ->
        console.log ">> Clean temp folders...".cyan
        Q.all [
            os.remove @build_temp_path
            os.remove @require_temp_path
        ]

module.exports = new Builder
