mp3 = '/base/doc/mp3/rain.mp3'
aac = '/base/doc/mp3/coins.mp4a'
empty_mp3 = '/base/doc/mp3/empty.mp3'

assert = chai.assert

p = new _mu.Player({
    mute: true
    volume: 0
    absoluteUrl: false
    baseDir: '/base/dist'
    engines: [
        {
            constructor: 'FlashMP3Core'
        },
        {
            constructor: 'FlashMP4Core'
        },
        {
            constructor: 'AudioCore'
        }
    ]
})

window.muplayer = p
