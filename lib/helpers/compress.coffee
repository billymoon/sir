compression = require 'compression'

module.exports = (app)->
  if app.program.compress
    app.server.use compression threshold: 0
