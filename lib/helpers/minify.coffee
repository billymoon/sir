minify = require 'express-minify'

module.exports = (app)->

  if app.program.minify
    app.server.use minify()
