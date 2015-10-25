log = require('./log')()
sc = require 'node-soundcloud'
URL = require 'url'
fs = require 'fs'
ID3 = undefined
id3 = undefined
TrackParser = require './TrackParser'
sanitize = require 'sanitize-filename'
id = "23aca29c4185d222f2e536f440e96b91"
path = require 'path'
winston = require 'winston'
EventEmitter = require 'events'
emitter = new EventEmitter

module.exports =
  class SCDL
    initLog: ->
      if @logging
        log.add winston.transports.File,
          filename: 'scdl.log'
          json: false
          level: 'debug'
          colorize: true
          prettyPrint: true

    initSC: ->
      sc.init
        id: id

    initDriver: ->
      ID3 = require './drivers/' + @driver
      id3 = new ID3

    on: ->
      emitter.on.apply emitter, arguments

    constructor: (options) ->
      sanitized =
        isTerminal: options.isTerminal || false
        logging: options.logging || false
        driver: options.driver || 'ffmpeg'
        output: options.output || false
        structure: options.structure || false

      @[key] = value for key, value of sanitized

      @initDriver()
      @initSC()
      @initLog()

    fatal: (args...) ->
      if @isTerminal
        log.error.apply log, args
        process.exit 0
      else throw new Error 'SCDL encountered a fatal error' + args

    url: (url, callback) ->
      @output_files = []
      sc.get '/resolve', {url: url}, (err, data) =>
        log.log "debug", err, data
        if err then @fatal err

        url = URL.parse data.location
        log.log "debug", "Getting", url.pathname
        sc.get url.pathname, {}, (err, resource) =>
          if err then @fatal err
          if typeof resource is "undefined" then return

          calls = []

          # is it a playlist?
          if "tracks" of resource
            calls.push [track, resource] for track in resource.tracks

          else
            # is it a collection of tracks or a single track?
            if Array.isArray resource then calls.push [track] for track in resource
            else calls.push [resource]

          totalDownloads = calls.length
          for call, i in calls
            call.push (files) =>
              @finishedDownloads++
              log.log "debug", "[FINISH] Total tracks", totalDownloads, "finishedDownloads", @finishedDownloads

              if totalDownloads is @finishedDownloads
                callback files

            call.push i

            @handleTrack.apply @, call

    output_files: []
    handleTrack: (track, playlist, callback, downloadId) ->
      log.log "debug", track
      if not track.stream_url
        log.log "warn", "skipped track"
        return
      parser = new TrackParser track, playlist
      if not track.downloadable then url = URL.parse track.stream_url
      else url = URL.parse track.download_url

      sc.get url.pathname, {}, (err, stream) =>
        if err then @fatal err

        dir = @output || process.cwd()
        if @structure then dir = dir + parser.getOutputPath()

        mp3 = sanitize track.title + ".mp3"
        jpg = sanitize track.title + ".jpg"

        @download stream.location, mp3, dir, =>
          if track.artwork_url then art = track.artwork_url
          else art = track.user.avatar_url

          @download art.replace("large", "t500x500.jpg"), jpg, dir, (filename) =>
            log.info "All files and meta data downloaded. Commencing tagging..."
            parsed = parser.parse()
            log.log "debug", "writing to", mp3, parsed
            id3.write mp3, parsed, jpg, (err) =>
              if err then @fatal err
              log.log "debug", "deleting", jpg
              fs.unlinkSync jpg
              @output_files.push mp3
              if callback then callback @output_files, downloadId

    activeDownloads: 0
    finishedDownloads: 0
    download: (url, filename, dir, callback) ->
      filename = dir + path.sep + filename

      log.log 'debug', 'downloading', url, filename
      urlp = URL.parse url
      http = require urlp.protocol.substr(0, urlp.protocol.length - 1)

      try
        stream = fs.createWriteStream filename
        req = http.request url

        req.once 'response', (res) =>
          try
            res.pipe stream

            res.once 'end', ->
              if ondata then res.removeListener 'data', ondata
              emitter.emit "end", filename, @activeDownloads
              callback filename

            if path.extname(filename) isnt ".jpg"
              @activeDownloads++
              emitter.emit "start", filename, @activeDownloads

            total = parseInt res.headers['content-length'], 10
            curr = 0

            res.on 'data', ondata = (chunk) ->
              curr += chunk.length
              percent = parseInt curr / total * 100
              emitter.emit "progress", percent, filename, @activeDownloads if percent <= 100 and path.extname(filename) isnt ".jpg"
          catch e
            @fatal e

        req.end()
      catch e
        @fatal e
