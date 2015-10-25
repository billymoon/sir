express = require 'express'

module.exports = (app, data)->
  app.server.use "/#{data.myurl}", express.static data.mypath, hidden: app.program.hidden