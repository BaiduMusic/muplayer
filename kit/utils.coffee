{ kit } = require 'nobone'

{
    readFile, outputFile, Promise
} = kit

module.exports =
    concat_files: (files, dest, separator = '') ->
        fc = []
        Promise.all(
            files.map (file) ->
                readFile(file, 'utf8').then (str) ->
                    fc.push str
                    Promise.resolve()
        ).then ->
            outputFile dest, fc.join(separator)
