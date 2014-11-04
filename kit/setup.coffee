{ kit } = require 'nobone'

{ spawn, log, path } = kit

class Setup
    start: ->
        spawn path.join('node_modules', '.bin', 'bower'), ['install']
        .then ->
            if process.env.quiet is 'true'
                return { install_flex_sdk: 'no' }

            kit.prompt_get [{
                name: 'install_flex_sdk'
                description: 'Whether Flex SDK or not? (yes/no)'
                default: 'no'
                pattern: /(yes)|(no)/
            }]
        .catch (e) ->
            if e.message is 'canceled'
                log '\n>> Canceled.'.red
                process.exit 0
        .then (opts) ->
            if opts.install_flex_sdk is 'yes'
                spawn 'npm', ['install', 'flex-sdk']
        .done ->
            log '>> Setup done.'.yellow

module.exports = new Setup
