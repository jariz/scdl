id3 = require 'id3-writer'
writer = new id3.Writer()

module.exports =
  class eyed3
    write: (file, meta, image, callback) ->
      image = new id3.Image image
      file = new id3.File file
      meta = new id3.Meta meta, [image]
      writer.setFile(file).write meta, callback