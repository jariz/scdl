ff = require 'ffmetadata'

module.exports =
  class ffmpeg
    write: (file, meta, image, callback) ->
      if meta.year then meta.date = meta.year
      ff.write file, meta, { attachments: [image] }, callback
