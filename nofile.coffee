# nofile-pre-require: coffee-script/register

module.exports = (task, option) ->
    nofile_builder = new (require './kit/nofile_builder')(dirname: __dirname)

    nofile_builder.build(option, 'option', [
        '-p, --port <8077>'
        '-r, --rebuild'
        '-c, --cli'
    ])

    nofile_builder.build(task, 'task', [
        'setup', 'build', 'doc',
        'server', 'test', 'coffeelint'
    ])
