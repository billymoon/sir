compression = require 'compression'

module.exports = (compress, server)->
  if compress
    server.use compression threshold: 0
