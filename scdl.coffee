clor = require 'clor'
winston = require 'winston'
log = undefined
sc = require 'node-soundcloud'
URL = require 'url'
fs = require 'fs'
multimeter = require 'multimeter'
multi = multimeter(process);
id3 = require 'id3-writer'
TrackParser = require './TrackParser'
writer = new id3.Writer()
async = require 'async'
sanitize = require 'sanitize-filename'
id = "23aca29c4185d222f2e536f440e96b91" #todo config or smth

module.exports =
  class SCDL
    initLog: ->
      log = new (winston.Logger)
        levels:
          debug: 1
          info: 2
          warn: 3
          error: 4
        colors:
          debug: 'green'
          info: 'blue'
          warn: 'yellow'
          error: 'red'

      log.add winston.transports.File,
        filename: 'scdl.log'
        json: false
        level: 'debug'
        colorize: true
        prettyPrint: true

    initSC: ->
      sc.init
        id: id

    constructor: ->
      @initSC()
      @initLog()

    isTerminal: false
    terminalMode: ->
      @isTerminal = not @isTerminal

      #workaround for annoying node warning
      multi.charm.setMaxListeners 100;

      multi.charm.reset();
      multi.write clor.white("SoundCloud Downloader").bold() + clor.gray(" By Jari Zwarts") + '\n'
      multi.write clor.yellow("Automatically downloads and tags SoundCloud tracks/playlists") + '\n\n'

      log.add winston.transports.Console,
        level: 'warn'
        prettyPrint: true
        colorize: true

      if not process.argv[2] then @fatal 'Please give me the soundcloud URL I should download (e.g. "scdl https://soundcloud.com/amistrngr/water")'

      @url process.argv[2]

    fatal: (args...) ->
      if @isTerminal
        multi.destroy()
        log.error.apply log, args
        process.exit 0
      else throw new Error 'SCDL encountered a fatal error' + args

    url: (url) ->
      sc.get '/resolve', { url: url }, (err, data) =>
        log.log "debug", err, data
        if err then @fatal err

        url = URL.parse data.location
        log.log "debug", "Getting", url.pathname
        sc.get url.pathname, {}, (err, resource) =>
          if err then @fatal err
          if typeof resource is "undefined" then return

          # is it a playlist?
          if "tracks" of resource
            @handleTrack track, resource for track in resource.tracks
            return

          # is it a collection of tracks or a single track?
          if Array.isArray resource then @handleTrack track for track in resource
          else @handleTrack resource

    handleTrack: (track, playlist) ->
      log.log "debug", track
      if not track.downloadable then url = URL.parse track.stream_url
      else url = URL.parse track.download_url

      sc.get url.pathname, {}, (err, stream) =>
        mp3 = sanitize track.title + ".mp3"
        jpg = sanitize track.title + ".jpg"

        @download stream.location, mp3, =>
          if track.artwork_url then art = track.artwork_url
          else art = track.user.avatar_url

          @download art.replace("large", "t500x500.jpg"), jpg, (filename) =>
            log.info "All files and meta data downloaded. Commencing tagging..."
            image = new id3.Image jpg
            mp3 = new id3.File mp3
            parser = new TrackParser track, playlist
            parsed = parser.parse()
            log.log "debug", "writing to", mp3, parsed
            meta = new id3.Meta parsed, [image]
            writer.setFile(mp3).write meta, (err) ->
              if err then @fatal err
              log.log "debug", "deleting", jpg
              fs.unlinkSync jpg

    activeDownloads: 0
    download: (url, filename, callback) ->
      log.log 'debug', 'downloading', url, filename
      urlp = URL.parse url
      http = require urlp.protocol.substr(0, urlp.protocol.length - 1)

      try
        stream = fs.createWriteStream filename
        req = http.request url

        req.once 'response', onresponse = (res) =>
          try
            res.pipe stream

            if not @isTerminal then return
            multi.write filename+"  \n"
            @activeDownloads++
            bar = multi 40, @activeDownloads + 3,
              width: 40

            total = parseInt res.headers['content-length'], 10
            curr = 0

            res.on 'data', ondata = (chunk) ->
              curr += chunk.length
              bar.percent parseInt curr / total * 100

          catch e
            @fatal e
          res.once 'end', onend = ->
            res.removeListener 'data', ondata
            callback filename, url

        req.end()
      catch e
        @fatal e
