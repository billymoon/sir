const compression = require('compression')

module.exports = function (app) {
  if (app.program.compress) {
    app.server.use(compression({threshold: 0}))
  }
}
