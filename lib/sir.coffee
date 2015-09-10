run = ->

  url = require 'url'
  fs = require 'fs'
  path = require 'path'
  exec = require('child_process').exec

  mkdirp = require 'mkdirp'
  program = require 'commander'
  express = require 'express'
  serveIndex = require 'serve-index'
  compression = require 'compression'
  morgan = require 'morgan'
  coffee = require 'coffee-script'
  marked = require 'marked'
  stylus = require 'stylus'
  jade = require 'jade'
  less = require 'less'
  sass = require 'node-sass'
  slm = require 'slm'
  mustache = require 'mustache'
  _ = require 'lodash'
  illiterate = require 'illiterate'
  beautify = require 'js-beautify'
  cheerio = require 'cheerio'
  tinylr = require 'tiny-lr'
  request = require 'request'
  proxy = require 'proxy-middleware'

  program.version(require('../package.json').version)
  .usage('[options] <dir>')
  .option('-p, --port <port>', 'specify the port [8080]', Number, 8080)
  .option('-h, --hidden', 'enable hidden file serving')
  .option('    --cache <cache-folder>', 'store copy of each served file in `cache` folder', String)
  .option('    --no-livereload', 'disable livereload watching served directory (add `lr` to querystring of requested resource to inject client script)')
  .option('    --no-logs', 'disable request logging')
  .option('-f, --format <fmt>', 'specify the log format string (npmjs.com/package/morgan)', 'dev')
  .option('    --compress', 'gzip or deflate the response')
  .option('    --exec <cmd>', 'execute command on each request')
  .option('    --no-cors', 'disable cross origin access serving')
  .option('    --vendor-path', 'display the path to the vendor libraries and exit')
  ## TODO: --fetch lib,lib,lib
  ## TODO: consider re-implementing these features...
  # .option('-i, --no-icons', 'disable icons')
  # .option('-d, --no-dirs', 'disable directory serving')
  # .option('-f, --favicon <path>', 'serve the given favicon')
  .parse process.argv

  if program.vendorPath
    console.log path.resolve path.join __dirname, '..', 'lib/extra/vendor'
    process.exit()

  mimes =
    html: 'text/html'
    css: 'text/css'
    js: 'application/javascript'
    xml: 'text/xml'
    xsl: 'text/xsl'

  handlers =
    less:
      process: (str)-> css=null; less.render(str, (e, compiled)-> css=compiled); css
      chain: 'css'
    stylus:
      process: (str)-> stylus.render str
      chain: 'css'
    scss:
      process: (str)-> sass.renderSync(data: str).css
      chain: 'css'
    sass:
      process: (str)-> sass.renderSync(data: str, indentedSyntax: true).css
      chain: 'css'
    coffee:
      process: (str)-> coffee.compile str, bare:true
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
    # TODO: better way to handle xml and xsl in slim - perhaps double barrel name?
    xmls:
      process: (str) -> beautify.html slm.render(str), indent_size: 4
      chain: 'xml'
    xslm:
      process: (str) -> beautify.html slm.render(str), indent_size: 4
      chain: 'xsl'

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

  slm.template.registerEmbeddedFunction 'scss', (str) ->
    '<style type="text/css">' + handlers.scss.process(str) + '</style>'

  slm.template.registerEmbeddedFunction 'sass', (str) ->
    '<style type="text/css">' + handlers.sass.process(str) + '</style>'

  sourcepath = path.resolve program.args[0] or '.'

  # setup the server
  server = express()

  # exec command
  if program.exec
    server.use (req, res, next) ->
      exec program.exec, next

  # compression
  if program.compress
    server.use compression threshold: 0

  # CORS access for files
  if program.cors
    server.use (req, res, next) ->
      res.setHeader 'Access-Control-Allow-Origin', '*'
      res.setHeader 'Access-Control-Allow-Methods', 'GET,PUT,POST,DELETE,OPTIONS'
      res.setHeader 'Access-Control-Allow-Headers', 'Content-Type, Authorization, Content-Length, X-Requested-With, Accept, x-csrf-token, origin'
      if req.method == 'OPTIONS'
        endStore res
      next()

  # request logging
  if program.logs
    server.use morgan program.format

  # http://stackoverflow.com/a/19215370/665261
  server.use (req, res, next)->
    oldWrite = res.write;
    oldEnd = res.end;

    chunks = [];

    res.write = (chunk)->
      chunks.push chunk
      oldWrite.apply res, arguments

    res.end = (chunk)->
      if chunk then chunks.push chunk

      body = Buffer.concat chunks

      filepath = req.originalUrl
      if program.cache && res.statusCode >= 200 && res.statusCode < 400
        resolvedpath = path.resolve path.join program.cache, path.dirname filepath
        filename = path.resolve path.join program.cache, filepath
        if fs.existsSync(resolvedpath) && fs.lstatSync(resolvedpath).isFile()
          fs.renameSync resolvedpath, resolvedpath + '.tmp'
          mkdirp.sync resolvedpath
          fs.renameSync resolvedpath + '.tmp', path.join resolvedpath, 'auto-index.html'
        else if fs.existsSync(filename) && fs.lstatSync(filename).isDirectory()
          filename = path.join filename, 'auto-index.html'
        else
          mkdirp.sync resolvedpath
        fs.writeFileSync filename, body

      oldEnd.apply res, arguments

    next()

  sources = if program.args.length then program.args else ['.']
  served = {}
  for source in sources
    mypaths = source.split '::'
    if mypaths and mypaths.length > 1
      myurl = mypaths.shift()
      served[myurl] = {proxy:mypaths.join('::')}
    else
      mypaths = source.split ':'
      myurl = if mypaths.length > 1 then mypaths.shift() else ''
      for mypath in mypaths
        served[myurl] = served[myurl] or {paths:[],files:[]}
        served[myurl].paths.push mypath
        served[myurl].files.push fs.readdirSync path.resolve mypath
  for myurl, items of served
    if items.proxy
      proxyurl = ('/'+myurl).replace(/^\/+/,'/')
      server.use proxyurl, proxy items.proxy
      console.log 'proxying ' + proxyurl + ' to ' + items.proxy
    else
      for mypath in items.paths
        server.use (req, res, next)->
          fallthrough = true
          _.each _.keys(handlers), (item, index)->
            ## TODO: safe alternative to `req._parsedUrl`
            replaced_path = req._parsedUrl.pathname.replace new RegExp("^\/?#{myurl}"), ""
            m = replaced_path.match new RegExp "^/?(.+)\\.#{handlers[item]?.chain}$"
            literate_path = "#{replaced_path}.md".replace(/^\//,'')
            compilable_path = !!m and "#{m[1]}.#{item}"
            literate_compilable_path = !!m and "#{m[1]}.#{item}.md"
            literate = null
            raw = null
            if !!fallthrough and (
                (fs.existsSync(path.resolve(path.join(mypath,literate_path))) and literate = true and raw = true) or !!m and (
                  fs.existsSync(path.resolve(path.join(mypath,compilable_path))) or (
                    fs.existsSync(path.resolve(path.join(mypath,literate_compilable_path))) and literate = true
                  )
                )
              )
              fallthrough = false
              currentpath = if !!raw then literate_path else if literate then literate_compilable_path else compilable_path
              currentpath = path.join mypath, currentpath
              str = fs.readFileSync(path.resolve currentpath).toString 'UTF-8'
              if !!literate then str = illiterate str
              if not raw then str = handlers[item].process str, path.resolve currentpath
              ## process lr to add livereload script to page
              if program.livereload and req.query.lr?
                lr_tag = """
                <script src="/livereload.js?snipver=1"></script>
                """
                $ = cheerio.load str
                if $('script').length
                  $('script').before lr_tag
                  str = $.html()
                else
                  str = lr_tag + str
              if !!literate and !!raw
                part = path.extname(replaced_path).replace(/^\./, '')
                ## TODO: perhaps use filetype for mime instead of plain ... #{part or 'plain'}"
                literate_mime = if mimes[part] then mimes[part] else "text/plain"
              res.setHeader 'Content-Type', if !!literate_mime then "#{literate_mime}; charset=utf-8" else if !!raw then "text/#{item}; charset=utf-8" else "#{mimes[handlers[item]?.chain]}; charset=utf-8"
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
              fileobject = generated:[], a:file.name, href:locals.directory.replace(/\/$/,'')+'/'+file.name
              extstr = file.name.match /(?:\.([^.]+))?\.([^.]+)$/
              if extstr
                ext = extstr[2]
                if handlers[ext]?.chain
                  fileobject.generated.push a:handlers[ext].chain, href:fileobject.href.replace /[^.]+$/, handlers[ext].chain
                ext = extstr[1]
                if !!ext
                  if handlers[ext]?.chain
                    fileobject.generated.push a:ext, href:fileobject.href.replace /\.[^.]+$/, ''
                    fileobject.generated.push a:handlers[ext].chain, href:fileobject.href.replace /[^.]+\.[^.]+$/, handlers[ext].chain
              if file.name.match /\./ then files.push fileobject else dirs.push fileobject
            callback 0, mustache.render """
            <ul>
              {{#dirs}}
              <li><a href="{{href}}">{{a}}</a></li>
              {{/dirs}}
              {{#files}}
              <li>
                <a href="{{href}}">{{a}}</a>
                {{#generated}}
                  [<a href="{{href}}">{{a}}</a>]
                {{/generated}}
              </li>
              {{/files}}
            </ul>
            """, dirs: dirs, files: files

  # livereload (add ?lr to url to activate - watches served paths)
  if program.livereload
    server.use(tinylr.middleware({ app: server }))
    # TODO: use https://www.npmjs.com/package/watchr
    # TODO: send served filename, not changed filename to handle preprocessed files
    fs.watch sourcepath, {recursive:true}, (e, filename)->
      request "http://127.0.0.1:#{program.port}/changed?files="+filename, (error, response, body)->
        console.log 'livereloaded due to change: ' + filename

  # start the server
  server.listen program.port, ->
    console.log 'serving %s on port %d', sourcepath, program.port  

module.exports = run: run