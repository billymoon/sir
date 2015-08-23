run = ->

  # process.on 'uncaughtException', (err) ->
  #   console.log err
  #   if err.code == 'EADDRINUSE'
  #     port = if program.port then 'port ' + program.port else 'the port'
  #     console.error 'looks like ' + port + ' is already in use\ntry a different port with: --port <PORT>'
  #   else
  #     console.error err
  #     # console.error err.syscall + ' ' + err.code

  url = require 'url'
  fs = require 'fs'
  path = require 'path' # resolve/join
  exec = require('child_process').exec

  # mkdirp = require 'mkdirp'
  program = require 'commander'
  express = require 'express'
  serveIndex = require 'serve-index'
  # compression = require 'compression'
  # morgan = require 'morgan'
  coffee = require 'coffee-script'
  marked = require 'marked'
  stylus = require 'stylus'
  jade = require 'jade'
  less = require 'less'
  slm = require 'slm'
  mustache = require 'mustache'
  _ = require 'lodash'
  illiterate = require 'illiterate'
  beautify = require 'js-beautify'
  # cheerio = require('cheerio')
  # tinylr = require('tiny-lr')
  # request = require('request')
  # onFinished = require('on-finished')

  program.version(require('../package.json').version)
  .usage('[options] [dir]')
  # .option('-F, --format <fmt>', 'specify the log format string', 'dev')
  .option('-p, --port <port>', 'specify the port [8080]', Number, 8080)
  .option('-h, --hidden', 'enable hidden file serving')
  # .option('-s, --no-stylus', 'disable stylus rendering')
  # .option('-j, --no-jade', 'disable jade rendering')
  # .option('    --no-less', 'disable less css rendering')
  # .option('    --cache <cache-folder>', 'store copy of each served file in `cache` folder', String)
  # .option('    --no-coffee', 'disable coffee script rendering')
  # .option('    --no-markdown', 'disable markdown rendering')
  # .option('    --no-illiterate', 'disable illiterate rendering')
  # .option('    --no-slim', 'disable slim rendering')
  # .option('-r  --livereload', 'enable livereload watching served directory (add `lr` to querystring of requested resource to inject client script)')
  # .option('-i, --no-icons', 'disable icons')
  # .option('-l, --no-logs', 'disable request logging')
  # .option('-d, --no-dirs', 'disable directory serving')
  # .option('-f, --favicon <path>', 'serve the given favicon')
  # .option('-c, --cors', 'allows cross origin access serving')
  # .option('    --compress', 'gzip or deflate the response')
  # .option('    --exec <cmd>', 'execute command on each request')
  .parse process.argv

  mimes =
    html: 'text/html'
    css: 'text/css'
    js: 'application/javascript'

  handlers =
    less:
      process: (str) ->
        css = null
        less.render str, (e, compiled) -> css = compiled
        css
      chain: 'css'
    stylus:
      process: (str)-> stylus.render str
      chain: 'css'
    coffee:
      process: (str)-> coffee.compile str
      chain: 'js'
    markdown:
      process: (str)-> beautify.html marked str
      chain: 'html'
    jade:
      process: (str, file) -> beautify.html jade.compile(str, filename: file)()
      chain: 'html'
    slim:
      process: (str) -> beautify.html slm.render(str), indent_size: 4
      chain: 'html'

  handlers.md = handlers.markdown
  handlers.slm = handlers.slim
  handlers.styl = handlers.stylus

  slm.template.registerEmbeddedFunction 'markdown', handlers.markdown.process

  slm.template.registerEmbeddedFunction 'coffee', (str) ->
    '<script>' + handlers.coffee.process(str) + '</script>'

  slm.template.registerEmbeddedFunction 'less', (str) ->
    '<style type="text/css">' + handlers.less.process(str) + '</style>'

  slm.template.registerEmbeddedFunction 'stylus', (str) ->
    '<style type="text/css">' + handlers.stylus.process(str) + '</style>'

  sourcepath = path.resolve program.args[0] or '.'

  # setup the server
  server = express()

  sources = if program.args.length then program.args else ['.']
  served = {}
  for source in sources
    mypaths = source.split ':'
    myurl = if mypaths.length > 1 then mypaths.shift() else ''
    for mypath in mypaths
      served[myurl] = served[myurl] || {}
      served[myurl].paths = (served[myurl].paths || []).concat mypath
      served[myurl].files = (served[myurl].files or []).concat fs.readdirSync path.resolve mypath
  for myurl, items of served
    for mypath in items.paths
      server.use (req, res, next)->
        fallthrough = true
        _.each _.keys(handlers), (item, index)->
          ## TODO: safe alternative to `req._parsedUrl`
          m = req._parsedUrl.pathname.match new RegExp "^/?(.+)\\.#{handlers[item]?.chain}$"
          ## TODO: consolidate literate and regular types
          literate_path = "#{req._parsedUrl.pathname}.md".replace(/^\//,'')
          compilable_path = !!m and "#{m[1]}.#{item}"
          literate_compilable_path = !!m and "#{m[1]}.#{item}.md"
          literate = null
          raw = null
          if !!fallthrough and (
              (fs.existsSync(path.resolve(literate_path)) and literate = true and raw = true) or !!m and (
                fs.existsSync(path.resolve(compilable_path)) or (
                  fs.existsSync(path.resolve(literate_compilable_path)) and literate = true
                )
              )
            )
            fallthrough = false
            currentpath = if raw then literate_path else if literate then literate_compilable_path else compilable_path
            str = fs.readFileSync(path.resolve currentpath).toString 'UTF-8'
            if !!literate then str = illiterate str
            if not raw then str = handlers[item].process str, path.resolve compilable_path
            ## TODO: bug - `http://localhost:8080/demo/sample-literate.coffee` shows content-type `text/less`
            res.setHeader 'Content-Type', if !!raw then "text/#{item}; charset=utf-8" else "#{mimes[handlers[item]?.chain]}; charset=utf-8"
            res.setHeader 'Content-Length', str.length
            res.end str
        next() if fallthrough
      server.use "/#{myurl}", express.static mypath, hidden:program.hidden
      server.use (req, res, next)->
        if req.query.format == 'json'
          req.headers.accept = 'application/json'
        else if req.query.format == 'text'
          req.headers.accept = 'text/plain'
        next()
      server.use "/#{myurl}", serveIndex mypath,
        'icons': false
        template: (locals, callback)->
          files = []
          dirs = []
          ## TODO: use combined file list, not just one folder
          # filelist = items.files.map (file)-> name: file
          # console.log served[myurl]
          _.each locals.fileList, (file, i)->
            fileobject = a:file.name, href:locals.directory.replace(/\/$/,'')+'/'+file.name
            if file.name.match /\./ then files.push fileobject else dirs.push fileobject
          callback 0, mustache.render """
          <ul>
            {{#dirs}}
            <li><a href="{{href}}">{{a}}</a></li>
            {{/dirs}}
            {{#files}}
            <li><a href="{{href}}">{{a}}</a></li>
            {{/files}}
          </ul>
          """, dirs: dirs, files: files

  # start the server
  server.listen program.port, ->
    console.log 'serving %s on port %d', sourcepath, program.port  

module.exports = run: run