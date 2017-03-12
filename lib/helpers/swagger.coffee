fs = require 'fs'
path = require 'path'

module.exports = (app)->
  if app.program.swagger
    swaggerFile = app.program.swagger
    if fs.lstatSync(swaggerFile).isFile()
      swaggerDir = path.dirname swaggerFile
      swaggerFiles = fs.readdirSync swaggerDir
      app.program.args.push 'swagger:node_modules/swagger-ui/dist'
      app.program.args.push 'swagger/edit:node_modules/swagger-editor'
      app.program.args.push "swagger/edit/#{swaggerDir}:#{swaggerDir}"
      # replace default config (originally: node_modules/swagger-editor/config/defaults.json)
      app.server.get '/swagger', (req, res, next)->
        if !req.query.url
          console.log "/swagger?url=edit/#{swaggerFile}"
          res.redirect "/swagger?url=edit/#{swaggerFile}"
        else
          next()
      app.server.get '/swagger/edit/config/defaults.json', (req, res, next)->
        res.end """
          {
            "disableCodeGen": true,
            "editorOptions": {
              "theme": "ace/theme/atom_dark"
            },
            "examplesFolder": "#{swaggerDir}/",
            "exampleFiles": #{JSON.stringify(swaggerFiles)},
            "enableTryIt": false,
            "disableNewUserIntro": true
          }
        """
    else
      throw Error 'option `--swagger` should be set as path to swagger file'