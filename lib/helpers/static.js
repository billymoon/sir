const express = require('express')

module.exports = function (app) {
  app.hooks.pathserver.push(data => app.server.use(`/${data.myurl}`, express.static(data.mypath, {hidden: app.program.hidden})))
}
