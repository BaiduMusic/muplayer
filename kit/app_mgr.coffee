nobone = require 'nobone'

{ kit, service, renderer } = nobone()
{
    log,
    copy,
    glob,
    spawn,
    remove,
    symlink,
    Promise,
    path: { join, basename }
} = kit

argv = process.argv
[ port, open ] = argv[3..4]
open = open is 'true'

main = ->
    switch argv[2]
        when 'setup'
            setup = new (require './setup')
            setup.start()

        when 'build'
            builder = new (require './builder')
            builder.start()

        when 'doc'
            doxx_bin = join 'node_modules', '.bin', 'doxx'
            remove 'doc'
            .then ->
                Promise.all([
                    spawn('compass', [
                        'compile'
                        '--sass-dir', 'src/css'
                        '--css-dir', 'doc/css'
                        '--no-line-comments'
                    ])
                    spawn(doxx_bin, [
                        '-d'
                        '-R', 'README.md'
                        '-t', 'MuPlayer 『百度音乐播放内核』'
                        '-s', 'dist'
                        '-T', 'doc_temp'
                        '--template', 'src/doc/base.jade'
                    ])
                ])
            .then ->
                Promise.all([
                    copy join('doc_temp', 'player.js.html'), join('doc', 'api.html')
                    copy join('doc_temp', 'index.html'), join('doc', 'index.html')
                ])
            .then ->
                remove 'doc_temp'
            .then ->
                # symlink from root_path to doc_path
                symlink_to = (from, to, type = 'dir') ->
                    symlink join('..', from), join('doc', to), type

                Promise.all [
                    symlink_to 'dist', 'dist'
                    symlink_to 'bower_components', 'bower_components'
                    symlink_to join('src', 'doc', 'img'), 'img'
                    symlink_to join('src', 'doc', 'mp3'), 'mp3'
                    symlink_to join('src', 'doc', 'js'), 'js'
                    symlink_to join('src', 'img', 'favicon.ico'), 'favicon.ico', 'file'
                    glob join('src', 'doc', '*.html')
                    .then (paths) ->
                        for p in paths
                            to = join('doc', basename p)
                            log '>> Link: '.cyan + p + ' -> '.cyan + to
                            symlink join('..', p), to
                ]
            .done ->
                log '>> Build doc done.'.yellow

        when 'server'
            service.use '/', renderer.static('doc')
            service.listen port, ->
                log '>> Server start at port: '.cyan + port

main()
