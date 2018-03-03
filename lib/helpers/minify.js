const minify = require('express-minify')

module.exports = function (app) {
  if (app.program.minify) {
    app.server.use(minify())
  }
}
