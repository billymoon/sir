const morgan = require('morgan')

module.exports = function (app) {
  // # TODO: merge logs and format options
  if (app.program.logs) {
    app.server.use(morgan(app.program.format))
  }
}
