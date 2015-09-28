winston = require 'winston'

module.exports = ->
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

  log.add winston.transports.Console,
    level: 'warn'
    prettyPrint: true
    colorize: true

  return log