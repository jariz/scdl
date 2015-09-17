module.exports =
  # TrackParser converts soundcloud track objects to id3-writer friendly objects
  class TrackParser
    constructor: (@track, @playlist) ->
    parse: ->
      parsed =
        comment: "Tagged with SCDL http://git.io/vZp18"

      #determine artist. if dashes are used, format title instead of using username as artist.
      dashIndex = @track.title.indexOf("-") #todo other types of dashes
      if dashIndex isnt -1
        parsed.artist = @track.title.substring 0, dashIndex - 1
        parsed.title = @track.title.substring dashIndex + 1
      else
        parsed.title = @track.title
        parsed.artist = @track.user.username

      parsed.genre = @track.genre

      if @playlist then parsed.album = @playlist.title

      #use year if available, else use year in which track was uploaded
      if @track.release_year then parsed.year = @track.release_year
      else parsed.year = new Date(@track.created_at).getFullYear()

      parsed.artist = parsed.artist.trim()
      parsed.title = parsed.title.trim()

      return parsed
