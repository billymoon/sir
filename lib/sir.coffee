module.exports = run: ->

  path = require 'path'

  app =
    server: require('express')()
    program: require 'commander'
    handlers: require './handlers' # pre-processor handlers
    hooks: # hooks for modules to attach to
      beforesend: []
      pathserver: []
    mimes:
      html: 'text/html'
      css: 'text/css'
      js: 'application/javascript'
      xml: 'text/xml'
      xsl: 'text/xsl'

  # options and usage
  app.program
    .version require('../package.json').version
    .usage '[options] <dir>'
    .option '-p, --port <port>', 'specify the port [8080]', Number, 8080
    .option '-h, --hidden', 'enable hidden file serving'
    .option '    --cache <cache-folder>', 'store copy of each served file in `cache` folder', String
    .option '    --no-livereload', 'disable livereload watching served directory (add `lr` to querystring of requested resource to inject client script)'
    .option '    --no-logs', 'disable request logging'
    .option '-f, --format <fmt>', 'specify the log format string (npmjs.com/package/morgan)', 'dev'
    .option '    --compress', 'gzip or deflate the response'
    .option '    --exec <cmd>', 'execute command on each request'
    .option '    --no-cors', 'disable cross origin access serving'
    ## TODO: consider re-implementing these features...
    # .option('-d, --no-dirs', 'disable directory serving')
    # .option('-f, --favicon <path>', 'serve the given favicon')
    .parse process.argv

  for helper_name in [
      'preprocess'
      'static'
      'mime'
      'dirlist'
      'exec'
      'compress'
      'cors'
      'cache'
      'logs'
    ]
    helper = require "./helpers/#{helper_name}"
    helper app

  ## TODO: make this a helper, avoiding livereload ordering problem
  parse = require './parse'
  served = parse app
  for myurl, items of served
    if items.proxy
      proxymod = require './proxy'
      proxymod app, mypath: items.proxy, myurl: myurl
    else
      do -> for mypath in items.paths
        for cb in app.hooks.pathserver
          cb mypath: mypath, myurl: myurl

  for helper_name in [
      'livereload'
    ]
    helper = require "./helpers/#{helper_name}"
    helper app

  # start the server
  app.server.listen app.program.port, ->
    console.log 'serving %s on port %d', path.resolve(app.program.args[0] or process.cwd()), app.program.port