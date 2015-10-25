module.exports = run: ->

  # core libs
  fs = require 'fs'
  path = require 'path'

  # vendor libs
  express = require 'express'
  program = require 'commander'

  # options and usage
  program
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
    # .option('-i, --no-icons', 'disable icons')
    # .option('-d, --no-dirs', 'disable directory serving')
    # .option('-f, --favicon <path>', 'serve the given favicon')
    .parse process.argv

  # hooks for modules to attach to
  hooks =
    beforesend: []
    pathserver: []

  # general config
  mimes =
    html: 'text/html'
    css: 'text/css'
    js: 'application/javascript'
    xml: 'text/xml'
    xsl: 'text/xsl'

  # pre-processor config
  handlers = require "./helpers/handlers"

  # setup the server
  server = express()

  app =
    server: server
    program: program
    handlers: handlers
    hooks: hooks
    mimes: mimes

  for val in [
      'preprocess'
      'static'
      'mime'
      'dirlist'
      'exec'
      'compress'
      'cors'
      'cache'
      'livereload'
      'logs'
    ]
    helper = require "./helpers/#{val}"
    helper app

  parse = require './helpers/parse'
  served = parse app
  for myurl, items of served
    if items.proxy
      proxymod = require './helpers/proxy'
      proxymod app, mypath: items.proxy, myurl: myurl
    else
      do -> for mypath in items.paths
        for cb in hooks.pathserver
          cb mypath: mypath, myurl: myurl

  # start the server
  server.listen program.port, ->
    console.log 'serving %s on port %d', path.resolve(app.program.args[0] or process.cwd()), program.port