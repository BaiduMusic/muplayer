#!node_modules/.bin/coffee

require 'coffee-script/register'
require 'colors'
os = require '../lib/os'
Q = require 'q'

coffee_bin = os.path.resolve os.path.join('node_modules', '.bin', 'coffee')

main = ->
    switch process.argv[2]
        when 'setup'
            setup = require './setup'
            setup.start()

        when 'build'
            builder = require './builder'
            builder.start()

        when 'doc'
            doxx_bin = 'node_modules/.bin/doxx'
            Q.fcall =>
                os.remove 'doc'
            .then =>
                Q.all([
                    os.spawn('compass', [
                        'compile'
                        '--sass-dir', 'src/css'
                        '--css-dir', 'doc/css'
                    ])
                    os.copy 'src/img', 'doc/img'
                    os.spawn(doxx_bin, [
                        '-d'
                        '-R', 'README.md'
                        '-t', "MuPlayer 『百度音乐播放内核』"
                        '-s', 'dist'
                        '-T', 'doc_temp'
                        '--template', 'src/doc/base.jade'
                    ])
                ])
            .then =>
                os.copy 'doc_temp/player.js.html', 'doc/api.html'
            .then =>
                os.copy 'doc_temp/index.html', 'doc/index.html'
            .then =>
                os.remove 'doc_temp'
            .then =>
                Q.all [
                    os.symlink '../dist', 'doc/dist', 'dir'
                    os.symlink '../bower_components', 'doc/bower_components', 'dir'
                    os.symlink '../lib/mp3', 'doc/mp3', 'dir'
                    os.symlink '../src/img/favicon.ico', 'doc/favicon.ico'
                    os.glob('src/doc/*.{html,xml}').then (paths) ->
                        for p in paths
                            to = 'doc/' + os.path.basename(p)
                            console.log ">> Link: ".cyan + p + ' -> '.cyan + to
                            os.symlink '../' + p, to
                ]
            .done =>
                console.log '>> Build doc done.'.yellow

        when 'server'
            port = process.argv[3]
            node_static = require 'node-static'
            file = new node_static.Server 'doc'

            require 'http'
            .createServer (req, res) ->
                req.addListener 'end', ->
                    file.serve req, res
                .resume()
            .listen port

            console.log (">> Server start at port: " + port).cyan

main()
