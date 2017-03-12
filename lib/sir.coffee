# prioritise natural files over derived, and indicate conflict in list
# robust watcher
module.exports = run: ->

  path = require 'path'

  # define main app config
  app =
    server: require('express')()
    program: require 'commander'
    hooks: # hooks for modules to attach to
      beforesend: []
      pathserver: []
    mimes:
      html: 'text/html'
      css: 'text/css'
      js: 'application/javascript'
      json: 'application/json'
      xml: 'text/xml'
      xsl: 'text/xsl'

  # options and usage
  app.program
    .version require('../package.json').version
    .usage '[options] <dir>'
    .option '-p, --port <port>', 'specify the port [8080]', Number, 8080
    .option '-h, --hidden', 'enable hidden file serving'
    .option '    --backup <backup-folder>', 'store copy of each served file in `backup` folder', String
    .option '    --no-livereload', 'disable livereload watching served directory (add `lr` to querystring of requested resource to inject client script)'
    .option '    --no-logs', 'disable request logging'
    .option '-f, --format <fmt>', 'specify the log format string (npmjs.com/package/morgan)', 'dev'
    .option '    --minify', 'minify code before serving'
    .option '    --compress', 'gzip or deflate the response'
    .option '    --exec <cmd>', 'execute command on each request'
    .option '    --no-cors', 'disable cross origin access serving'
    .option '    --babel', 'pass all js through babel to convert to more js :)'
    .parse process.argv

  app.handlers = require('./handlers')(app.program) # pre-processor handlers

  for helper_name in [
      'minify'
      'preprocess'
      'static'
      'mime'
      'dirlist'
      'exec'
      'compress'
      'cors'
      'backup'
      'logs'
      'core' # main bootstrap, requires parse and proxy
      'livereload'
    ]
    helper = require "./helpers/#{helper_name}"
    helper app

  startServer = (port, cb)->
    try
      console.log 'going to try %s', port
      app.server.listen app.program.port, ->
        console.log 'serving %s on port %d', path.resolve(app.program.args[0] or process.cwd()), app.program.port
      app.server.on 'error', (err)->
        console.log 'cool'
      # app.server.once 'close', ()->
      #   cb port
      #   app.server.close()
    catch
      console.log 'going to enter loop %s', port + 1
      startServer port + 1, cb

  # start the server
  startServer 8080
