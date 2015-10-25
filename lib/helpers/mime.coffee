module.exports = (app)->
  app.hooks.pathserver.push (data)->
    app.server.use (req, res, next)->
      if req.query.format == 'json'
        req.headers.accept = 'application/json'
      else if req.query.format == 'text'
        req.headers.accept = 'text/plain'
      next()
