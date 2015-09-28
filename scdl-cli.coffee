multimeter = require 'multimeter'
multi = multimeter(process);
scdl = require './scdl'
clor = require 'clor'
cmd = require 'commander'
log = require('./log')()

module.exports = ->
  #workaround for annoying node warning
  multi.charm.setMaxListeners 100;

  multi.charm.reset();
  console.log clor.white("SoundCloud Downloader").bold() + clor.gray(" By Jari Zwarts")
  console.log clor.yellow("Automatically downloads and tags SoundCloud tracks/playlists") + '\n'

  cmd.version("0.1")
    .usage("[options] <url>")
    .option("-d, --driver [value]", "ID3 tagging driver, either ffmpeg or eyed3.", /^(ffmpeg|eyed3)$/i, 'ffmpeg')
    .option("-l, --logging", "If present, a scdl.log will be created in the current directory.")
    .option("-o, --output-directory [value]", "Change output directory in which files will be stored. (no trailing slash)")
    .option("-s, --directory-structure", "Organise downloaded tracks into their own directories.")
    .parse process.argv

  if not cmd.args[0]
    log.error 'Please give me the soundcloud URL I should download (e.g. "scdl https://soundcloud.com/amistrngr/water")'
    cmd.outputHelp()

  SCDL = new scdl
    isTerminal: true
    logging: cmd.logging is true
    driver: cmd.driver
    output: cmd.outputDirectory
    structure: cmd.directoryStructure

  SCDL.url cmd.args[0], (files) ->
    log.info "All done. byebye.", files
    setTimeout ->
#      multi.destroy()
      process.exit 0
    , 500