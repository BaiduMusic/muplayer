os = require '../lib/os'
Q = require 'q'

class Setup
    constructor: ->

    start: ->
        Q.fcall ->
            os.spawn 'node_modules/.bin/bower', ['install']
        .then ->
            if process.env.quiet == 'true'
                return { install_flex_sdk: 'no' }

            os.prompt_get [{
                name: 'install_flex_sdk'
                description: 'Whether Flex SDK or not? (yes/no)'
                default: 'no'
                pattern: /(yes)|(no)/
            }]
        .catch (e) ->
            if e.message is 'canceled'
                console.log '\n>> Canceled.'.red
                process.exit 0

        .then (opts) =>
            if opts.install_flex_sdk is 'yes'
                os.spawn 'npm', ['install', 'flex-sdk']
        .done ->
            console.log ">> Setup done.".yellow

module.exports = new Setup
