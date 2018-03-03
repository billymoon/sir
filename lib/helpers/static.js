const express = require('express')

module.exports = function (app) {
  // TODO: get this to work with livereload
  app.hooks.pathserver.push(data => app.server.use(`/${data.myurl}`, express.static(data.mypath, {hidden: app.program.hidden})))
}
