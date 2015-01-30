{ kit } = require 'nobone'

{ _, spawn, log, path: { join } } = kit

class Setup
    start: ->
        spawn join('node_modules', '.bin', 'bower'), ['install']
        .then ->
            if process.env.quiet is 'true'
                return { install_flex_sdk: 'no' }

            kit.promptGet [{
                name: 'install_flex_sdk'
                description: 'Whether to install Flex SDK or not? (y/n)'
                default: 'n'
                pattern: /(y)|(n)/
            }]
        .then (opts) ->
            if opts.install_flex_sdk is 'y'
                spawn 'npm', ['install', 'flex-sdk']
        .then =>
            @build_zepto()
        .catch (e) ->
            if e.message is 'canceled'
                log '\n>> Canceled.'.red
                process.exit 0
        .done ->
            log '>> Setup done.'.yellow

    build_zepto: ->
        zepto_path = join 'bower_components', 'zeptojs'
        mods = 'zepto event ajax ie selector data callbacks deferred stack ios3'

        log '>> Install zepto dependencies.'.cyan
        spawn 'npm', ['install'], {
            cwd: zepto_path
        }
        .then ->
            coffee_bin = join 'node_modules', '.bin', 'coffee'

            log '>> Build Zepto with: '.cyan + mods.green

            spawn coffee_bin, ['make', 'dist'], {
                cwd: zepto_path
                env: _.defaults(
                    { MODULES: mods }
                    process.env
                )
            }

module.exports = new Setup()
