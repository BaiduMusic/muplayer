nobone = require 'nobone'
nofile_builder = require './kit/nofile_builder'

{
    kit,
    kit: { path, spawn, Promise }
} = nobone

kit.require 'colors'

module.exports = (task, option) ->
    nofile_builder._dirname = __dirname

    nofile_builder.build(option, 'option', [
        '-p, --port <8077>'
        '-r, --rebuild'
        '-c, --cli'
    ])

    nofile_builder.build(task, 'task', [
        'setup', 'build', 'doc',
        'server', 'test', 'coffeelint'
    ])
