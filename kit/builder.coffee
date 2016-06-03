kit = require 'nokit'

br = kit.require 'brush'

{
    _, log, copy, glob, spawn, remove, Promise,
    path: { join }
} = kit

class Builder
    constructor: ->
        @src_path = 'src'
        @dist_path = 'dist'
        @lib_path = 'lib'
        @doc_path = join 'src', 'doc'
        @build_temp_path = 'build_temp'
        @require_temp_path = 'require_temp'

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
        .catch ->
            self.clean()

    copy_to_dist: (from, to) =>
        to = join @dist_path, to
        copy(from, to).then ->
            log br.cyan('>> Copy: ') + from + br.green(' -> ') + to

    update_build_dir: ->
        self = @
        {
            src_path, dist_path, build_temp_path,
            lib_path, doc_path, copy_to_dist
        } = @

        from_js = join src_path, 'js'
        to_js = join build_temp_path, 'js'

        glob join(dist_path, '**', '*')
        .then (paths) ->
            Promise.all(
                # swf文件默认不处理，由complie_as时自己决定是否重编
                _.reject(paths, (path) ->
                    /\.(swf|cache)$/.test(path)
                ).map (path) ->
                    remove (path)
                    log br.cyan('>> Clean: ') + path
            )
        .then ->
            copy(from_js, to_js).then ->
                log br.cyan('>> Copy: ') + from_js + br.green(' -> ') + build_temp_path
        .then ->
            Promise.all([
                copy_to_dist join(lib_path, 'expressInstall.swf'), 'expressInstall.swf'
                copy_to_dist join(doc_path, 'mp3', 'empty.mp3'), 'empty.mp3'
            ])

    compile_all_coffee: ->
        { build_temp_path } = @

        kit.require 'drives'

        kit.warp join(build_temp_path, '**', '*.coffee')
        .load kit.drives.auto 'compile'
        .run build_temp_path

    combine_js: (options = {}) ->
        log br.cyan('>> Compile client js with requirejs ...')

        {
            dist_path, copy_to_dist,
            require_temp_path, build_temp_path
        } = @
        requirejs = require 'requirejs'

        opts_pc =
            appDir: build_temp_path
            baseUrl: 'js'
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
            removeCombined: false
            pragmas:
                FlashCoreExclude: false
            # 为映射muplayer这个namespace
            paths:
                'muplayer': '.'

        opts_pc = _.extend(opts_pc, options.pc)

        new Promise (resolve) ->
            # PC
            requirejs.optimize opts_pc, (buildResponse) ->
                log br.cyan('>> r.js for PC')
                log buildResponse

                Promise.all(
                    opts_pc.modules.map (mod) ->
                        file = mod.name.replace(/^muplayer/, 'js') + '.js'
                        from = join(require_temp_path, file)
                        to = file.split('/').slice(-1)[0]
                        copy_to_dist from, to
                ).then ->
                    opts_webapp = _.cloneDeep opts_pc
                    opts_webapp.modules = [
                        {
                            name: 'muplayer/player'
                        }
                    ]

                    opts_webapp =_.extend(opts_webapp, options.webapp)
                    opts_webapp.pragmas.FlashCoreExclude = true

                    # Webapp
                    requirejs.optimize opts_webapp, (buildResponse) ->
                        log br.cyan('>> r.js for WebApp')
                        log buildResponse

                        zepto_path = join(require_temp_path, 'js', 'lib', 'zepto')

                        Promise.resolve [
                            join(zepto_path, 'mock.js')
                            join(zepto_path, 'callbacks.js')
                            join(zepto_path, 'deferred.js')
                            join(zepto_path, 'jqueryCompatible.js')
                        ]
                        .then (file_list) ->
                            mod = opts_webapp.modules[0]
                            file = join require_temp_path, (mod.name.replace(/^muplayer/, 'js') + '.js')
                            fname = 'zepto-' + file.split('/').slice(-1)[0]
                            # utils.concat_files(file_list, join(dist_path, fname), ';')
                            file_list.push(file)
                            kit.warp(file_list).load(
                              kit.drives.concat join(dist_path, fname)
                            ).run()
                        .then ->
                            log br.cyan('>> Compile client js done.')
                            resolve()
                        .catch (err) ->
                            log err

    compress_js: (files = []) ->
        { dist_path } = @

        compress = (path) ->
            spawn 'uglifyjs', [
                '-mt'
                '-o', path + '.min.js'
                path + '.js'
            ]

        files = [
            'player'
            'zepto-player'
        ].concat(files)

        Promise.all(
            files.map (path) ->
                compress join(dist_path, path)
        ).then ->
            log br.cyan('>> Compress js done.')

    add_license: (match = '*.js') ->
        { dist_path } = @
        cfg = require '../bower'
        info = """
            // @license
            // Baidu Music Player: #{cfg.version}
            // -------------------------
            // (c) 2014 FE Team of Baidu Music
            // Can be freely distributed under the BSD license.\n
        """

        glob join(dist_path, match)
        .then (paths) ->
            Promise.all _.map(paths, (path) ->
                kit.readFile(path, 'utf8').then (str) ->
                    log br.cyan('>> License info added: ') + path
                    kit.outputFile path, info + str
            )

    complie_as: ->
        { src_path, dist_path } = @

        try
            flex_sdk = require 'flex-sdk'
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
                    kit.err err
                else
                    log stdout
                    log stderr

        Promise.all([
            compile 'MP3Core', 'muplayer_mp3'
            compile 'MP4Core', 'muplayer_mp4'
        ]).then ->
            log br.cyan('>> Build AS done.')

    clean: ->
        { build_temp_path, require_temp_path } = @
        log br.cyan('>> Clean temp folders...')
        Promise.all [
            remove build_temp_path
            remove require_temp_path
        ]

module.exports = Builder
