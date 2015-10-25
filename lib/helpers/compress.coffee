compression = require 'compression'

module.exports = (app, data)->
  if app.program.compress
    app.server.use compression threshold: 0
