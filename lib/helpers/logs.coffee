morgan = require 'morgan'

module.exports = (logs, server)->
  if logs
    server.use morgan logs
