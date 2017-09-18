module.exports = function (app) {
  app.hooks.pathserver.push(data =>
    app.server.use(function (req, res, next) {
      if (req.query.format === 'json') {
        req.headers.accept = 'application/json'
      } else if (req.query.format === 'text') {
        req.headers.accept = 'text/plain'
      }
      next()
    })
  )
}
