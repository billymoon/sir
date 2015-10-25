morgan = require 'morgan'

module.exports = (app)->
  ## TODO: merge logs and format options
  if app.program.logs
    app.server.use morgan app.program.format
