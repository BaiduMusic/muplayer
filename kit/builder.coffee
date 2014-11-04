process.env.NODE_ENV = 'production'

gulp = require 'gulp'
gulp_concat = require 'gulp-concat'
nobone = require 'nobone'

{
    kit,
    renderer
} = nobone(renderer: {})

{
    _,
    Promise,
    log,
    copy,
    glob,
    spawn,
    remove,
    path: { join, relative }
} = kit


class Builder
    constructor: ->
        @src_path = 'src'
        @build_temp_path = 'build_temp'
        @require_temp_path = 'require_temp'
        @dist_path = 'dist'
        @lib_path = 'lib'
        @doc_path = 'doc'

    start: ->
        self = @
        @update_build_dir()
        .then ->
            self.compile_all_coffee()
        .then ->
            self.combine_js()
        .then ->
            self.compress_js()
        .then ->
            self.add_license()
        .then ->
            self.complie_as()
        .then ->
            self.clean()
        .done ->
            console.log '>> Build done.'.yellow

    copy_to_dist: (from, to) =>
        to = join @dist_path, to
        copy(from, to).then ->
            log '>> Copy: '.cyan + from + ' -> '.green + to

    update_build_dir: ->
        self = @
        copy_to_dist = @copy_to_dist
        from = join 'src', 'js'

        glob join(@dist_path, '**', '*')
        .then (paths) ->
            Promise.all(
                # swf文件默认不处理，由complie_as时自己决定是否重编
                _.reject(paths, (path) ->
                    /\.(swf|cache)$/.test(path)
                ).map (path) ->
                    remove (path)
                    log '>> Clean: '.cyan + path
            )
        .then ->
            copy(from, join(self.build_temp_path, 'js')).then ->
                kit.log '>> Copy: '.cyan + from + ' -> '.green + self.build_temp_path
        .then ->
            Promise.all([
                copy_to_dist join(self.lib_path, 'expressInstall.swf'), 'expressInstall.swf'
                copy_to_dist join(self.doc_path, 'mp3', 'empty.mp3'), 'empty.mp3'
            ])

    compile_all_coffee: ->
        self = @
        coffeescript = require 'coffee-script'

        glob join(self.build_temp_path, '**', '*.coffee')
        .then (coffee_list) ->
            Promise.all coffee_list.map (path) ->
                js_path = path.replace(/(\.coffee)$/, '') + '.js'

                kit.readFile(path, 'utf8').then (str) ->
                    try
                        return coffeescript.compile(str, { bare: true })
                    catch e
                        log ">> Error: #{path} \n#{e}".red
                .then (code) ->
                    kit.outputFile(js_path, code).then ->
                        remove(path)
                    .then ->
                        log '>> Compiled: '.cyan + path

    combine_js: (opts) ->
        self = @
        { copy_to_dist, dist_path, require_temp_path } = @

        log '>> Compile client js with requirejs ...'.cyan

        requirejs = kit.require 'requirejs'

        opts_pc =
            appDir: @build_temp_path
            baseUrl: 'js/'
            dir: require_temp_path

            optimize: 'none'
            optimizeCss: 'standard'
            modules: [
                {
                    name: 'muplayer/player'
                },
                {
                    name: 'muplayer/plugin/equalizer'
                },
                {
                    name: 'muplayer/plugin/lrc'
                }
            ]
            fileExclusionRegExp: /^\./
            removeCombined: true
            pragmas:
                FlashCoreExclude: false
            # 为映射muplayer这个namespace
            paths:
                'muplayer': '.'

        new Promise (resolve, reject) ->
            # PC
            requirejs.optimize opts_pc, (buildResponse) ->
                log '>> r.js for PC'.cyan
                log buildResponse

                Promise.all([
                    copy_to_dist join(require_temp_path, 'js', 'player.js'), 'player.js'
                    copy_to_dist join(require_temp_path, 'js', 'plugin', 'equalizer.js'), 'equalizer.js'
                    copy_to_dist join(require_temp_path, 'js', 'plugin', 'lrc.js'), 'lrc.js'
                ]).then ->
                    opts_webapp = _.cloneDeep opts_pc
                    opts_webapp.pragmas.FlashCoreExclude = true
                    opts_webapp.modules = [
                        {
                            name: 'muplayer/player'
                        }
                    ]

                    # Webapp
                    requirejs.optimize opts_webapp, (buildResponse) ->
                        log '>> r.js for WebApp'.cyan
                        log buildResponse
                        glob join(require_temp_path, 'js', 'lib', 'zepto', '**', '*.js')
                        .then (file_list) ->
                            file_list.push(join require_temp_path, 'js', 'player.js')
                            gulp.src(file_list)
                                .pipe(gulp_concat 'zepto-player.js')
                                .pipe(gulp.dest dist_path)
                            log '>> Compile client js done.'.cyan
                            resolve()

    compress_js: ->
        compress = (path) ->
            spawn join('node_modules', '.bin', 'uglifyjs'), [
                '-mt'
                '-o', path + '.min.js'
                path + '.js'
            ]

        Promise.all(
            [
                join @dist_path, 'player'
                join @dist_path, 'zepto-player'
            ].map (path) ->
                compress path
        ).then ->
            log '>> Compress js done.'.cyan

    add_license: ->
        cfg = require '../bower'
        info = """
            // @license
            // Baidu Music Player: #{cfg.version}
            // -------------------------
            // (c) 2014 FE Team of Baidu Music
            // Can be freely distributed under the BSD license.\n
        """
        glob join(@dist_path, '*.js')
        .then (paths) ->
            Promise.all _.map(paths, (path) ->
                kit.readFile(path, 'utf8').then (str) ->
                    log '>> License info added: '.cyan + path
                    kit.outputFile path, info + str
            )

    complie_as: ->
        { src_path, dist_path } = @

        try
            flex_sdk = kit.require 'flex-sdk'
        catch e
            return log '>> Warn: '.yellow + e.message

        compile = (src, dist) ->
            spawn flex_sdk.bin.mxmlc, [
                '-benchmark=false'
                '-incremental=true'
                '-show-actionscript-warnings=true'
                '-static-link-runtime-shared-libraries=true'
                '-o', join(dist_path, "#{dist}.swf")
                join(src_path, 'as', "#{src}.as")
            ], (err, stdout, stderr) ->
                if err
                    kit.err err.stack.red
                else
                    log stdout
                    log stderr

        Promise.all([
            compile 'MP3Core', 'muplayer_mp3'
            compile 'MP4Core', 'muplayer_mp4'
        ]).then ->
            log '>> Build AS done.'.cyan

    clean: ->
        log '>> Clean temp folders...'.cyan
        Promise.all [
            remove @build_temp_path
            remove @require_temp_path
        ]

module.exports = new Builder
