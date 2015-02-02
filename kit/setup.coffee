{ kit } = require 'nobone'

{ _, spawn, log, path: { join } } = kit

kit.require 'colors'

class Setup
    start: ->
        spawn 'bower', ['install']
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
            log '>> Build Zepto with: '.cyan + mods.green
            spawn 'coffee', ['make', 'dist'], {
                cwd: zepto_path
                env: _.defaults(
                    { MODULES: mods }
                    process.env
                )
            }

module.exports = new Setup()
