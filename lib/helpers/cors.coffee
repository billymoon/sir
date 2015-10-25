module.exports = (app, data)->
  if app.program.cors
    app.server.use (req, res, next) ->
      res.setHeader 'Access-Control-Allow-Origin', '*'
      res.setHeader 'Access-Control-Allow-Methods', 'GET,PUT,POST,DELETE,OPTIONS'
      res.setHeader 'Access-Control-Allow-Headers', 'Content-Type, Authorization, Content-Length, X-Requested-With, Accept, x-csrf-token, origin'
      # if req.method == 'OPTIONS'
      #   # TODO: what was meant to happen here?
      #   endStore res
      next()
