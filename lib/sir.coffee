run = ->
  process.on 'uncaughtException', (err) ->
    console.log err
    if err.code == 'EADDRINUSE'
      port = if program.port then 'port ' + program.port else 'the port'
      console.error 'looks like ' + port + ' is already in use\ntry a different port with: --port <PORT>'
    else
      console.error err.syscall + ' ' + err.code

  ###*
  # Module dependencies.
  ###

  url = require('url')
  fs = require('fs')
  join = require('path').join
  resolve = require('path').resolve
  path = require('path')
  exec = require('child_process').exec

  mkdirp = require('mkdirp')

  program = require('commander')

  express = require('express')
  compression = require('compression')
  morgan = require('morgan')

  # TODO: use https://www.npmjs.com/package/serve-index
  directory = require('../lib/directory/directory.js')

  coffee = require('coffee-script')
  marked = require('marked')
  stylus = require('stylus')
  jade = require('jade')
  less = require('less')
  slm = require('slm')

  illiterate = require('illiterate')
  beautify = require('js-beautify')
  cheerio = require('cheerio')
  tinylr = require('tiny-lr')
  request = require('request')

  onFinished = require('on-finished')

  # CLI
  program.version(require('../package.json').version)
  .usage('[options] [dir]')
  .option('-F, --format <fmt>', 'specify the log format string', 'dev')
  .option('-p, --port <port>', 'specify the port [8080]', Number, 8080)
  .option('-H, --hidden', 'enable hidden file serving')
  .option('-S, --no-stylus', 'disable stylus rendering')
  .option('-J, --no-jade', 'disable jade rendering')
  .option('    --no-less', 'disable less css rendering')
  .option('    --cache <cache-folder>', 'store copy of each served file in `cache` folder', String)
  .option('    --no-coffee', 'disable coffee script rendering')
  .option('    --no-markdown', 'disable markdown rendering')
  .option('    --no-illiterate', 'disable illiterate rendering')
  .option('    --no-slim', 'disable slim rendering')
  .option('-R  --livereload', 'enable livereload watching served directory (add `lr` to querystring of requested resource to inject client script)')
  .option('-I, --no-icons', 'disable icons')
  .option('-L, --no-logs', 'disable request logging')
  .option('-D, --no-dirs', 'disable directory serving')
  .option('-f, --favicon <path>', 'serve the given favicon')
  .option('-C, --cors', 'allows cross origin access serving')
  .option('    --compress', 'gzip or deflate the response')
  .option('    --exec <cmd>', 'execute command on each request').parse process.argv

  # sourcepath
  sourcepath = resolve(program.args[0] or '.')

  # setup the server
  server = express()

  output = null
  endStore = (res, out)->
    output = out
    res.end output

  # logger
  # TODO: accept log format
  # if (program.logs) server.use(morgan(morgan.compile(program.format)));
  if program.logs
    server.use morgan('dev')

  if program.livereload
    server.use(tinylr.middleware({ app: server }))
    # TODO: use https://www.npmjs.com/package/watchr
    # TODO: send served filename, not changed filename to handle preprocessed files
    fs.watch sourcepath, {recursive:true}, (e, filename)->
      request "http://127.0.0.1:#{program.port}/changed?files="+filename, (error, response, body)->
        console.log 'livereloaded due to change: ' + filename

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

  # slm template helpers
  slm.template.registerEmbeddedFunction 'markdown', marked

  slm.template.registerEmbeddedFunction 'coffee', (str) ->
    '<script>' + coffee.compile(str) + '</script>'

  slm.template.registerEmbeddedFunction 'less', (str) ->
    css = undefined
    less.render str, (e, compiled) ->
      css = compiled
      return
    '<style type="text/css">' + css + '</style>'

  slm.template.registerEmbeddedFunction 'stylus', (str) ->
    '<style type="text/css">' + stylus.render(str) + '</style>'

  # file types for plain serving and alter-ego extension rendering
  types =
    coffee:
      ext: 'coffee'
      next: 'js'
      mime: 'application/javascript'
      flag: program.coffee
      process: (str, file) ->
        coffee.compile str
    litcoffee:
      ext: 'coffee.md'
      next: 'js'
      mime: 'application/javascript'
      flag: program.coffee
      process: (str, file) ->
        coffee.compile str, literate: true
    litjs:
      ext: 'js.md'
      next: 'js'
      mime: 'application/javascript'
      flag: program.illiterate
      process: (str, file) ->
        illiterate str
    jade:
      ext: 'jade'
      next: 'html?'
      mime: 'text/html'
      flag: program.jade
      process: (str, file) ->
        fn = jade.compile(str, filename: file)
        fn()
    slim:
      ext: 'slim'
      next: 'html?'
      mime: 'text/html'
      flag: program.slim
      process: (str, file) ->
        beautify.html slm.render(str), indent_size: 4
    markdown:
      ext: 'md'
      next: 'html?'
      mime: 'text/html'
      flag: program.markdown
      process: (str, file) ->
        marked str
    litcoffeemd:
      ext: 'coffee.md'
      next: 'html?'
      mime: 'text/html'
      flag: program.markdown
      process: (str, file) ->
        marked str
    stylus:
      exts: ['styl']
      next: 'css'
      mime: 'text/css'
      flag: program.stylus
      process: (str, file) ->
        stylus.render str
    less:
      ext: 'less'
      next: 'css'
      mime: 'text/css'
      flag: program.less
      process: (str, file) ->
        css = undefined
        less.render str, (e, compiled) ->
          css = compiled
        css

  ## https://github.com/strongloop/express/issues/1765
  # var handlers = [customMiddleware1, customMiddleware2];
  #
  # function mySuperMiddleware(req, res, next) {
  #         function run(index) {
  #             if (index < handlers.length) {
  #                 handlers[index](req, res, function (err) {
  #                     if (err) {
  #                         return next(err);
  #                     }
  #                     index += 1;
  #                     run(index);
  #                 });
  #             } else {
  #                 next();
  #             }
  #         }
  #         run(0);
  # };
  #
  # app.use(mySuperMiddleware);

  setup = (type) ->
    tech = types[type]
    server.use (req, res, next) ->
      rex = new RegExp('\\.' + tech.next + '$')
      if !url.parse(req.originalUrl).pathname.match(rex)
        return next()
      file = join(sourcepath, decodeURI(url.parse(req.url).pathname))
      rend = file.replace(rex, '.' + tech.ext)
      if fs.existsSync(rend)
        fs.readFile rend, 'utf8', (err, str) ->
          if err
            return next(err)
          try
            str = tech.process(str, file)
            if !!req.query.lr
              lr_tag = """
              <script src="/livereload.js?snipver=1"></script>
              """
              $ = cheerio.load str
              if $('script').length
                $('script').before lr_tag
                str = $.html()
              else
                str = lr_tag + str
            # custom function can use/discard args as needed
            res.setHeader 'Content-Type', tech.mime
            res.setHeader 'Content-Length', Buffer.byteLength(str)
            res.end str
          catch err
            next err
      else
        # allow other handlers to have a bash at the same extension
        next()

    server.use (req, res, next) ->
      rex = new RegExp('\\.' + tech.ext + '$')
      if !req.url.match(rex)
        return next()
      file = join(sourcepath, decodeURI(url.parse(req.url).pathname))
      if fs.existsSync(file)
        fs.readFile file, 'utf8', (err, str) ->
          if err
            return next(err)
          try
            res.setHeader 'Content-Type', 'text/plain'
            res.setHeader 'Content-Length', Buffer.byteLength(str)
            endStore res, str
          catch err
            next err

  # exec command
  if program.exec
    server.use (req, res, next) ->
      exec program.exec, next

  # do setup for each defined renderable extension
  for type of types
    if types[type].flag
      setup type

  # CORS access for files
  if program.cors
    server.use (req, res, next) ->
      res.setHeader 'Access-Control-Allow-Origin', '*'
      res.setHeader 'Access-Control-Allow-Methods', 'GET,PUT,POST,DELETE,OPTIONS'
      res.setHeader 'Access-Control-Allow-Headers', 'Content-Type, Authorization, Content-Length, X-Requested-With, Accept, x-csrf-token, origin'
      if req.method == 'OPTIONS'
        endStore res
      next()

  # compression
  if program.compress
    server.use compression()

  # static files
  # TODO: use https://www.npmjs.com/package/serve-static
  server.use express.static(sourcepath, hidden: program.hidden)
  server.use express.static(__dirname + '/../lib/extra', hidden: program.hidden)

  # directory serving
  if program.dirs
    server.use directory(sourcepath,
      hidden: program.hidden
      icons: program.icons)
    server.use directory(__dirname + '/../lib/extra',
      hidden: program.hidden
      icons: program.icons)

  # start the server
  server.listen program.port, ->
    console.log 'serving %s on port %d', sourcepath, program.port

module.exports = run: run
