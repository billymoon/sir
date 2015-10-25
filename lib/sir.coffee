run = ->

  # core libs
  fs = require 'fs'
  path = require 'path'

  # vendor libs
  express = require 'express'
  serveIndex = require 'serve-index'
  proxy = require 'proxy-middleware'
  program = require 'commander'
  _ = require 'lodash'
  illiterate = require 'illiterate'
  mustache = require 'mustache'

  # options and usage
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
  ## TODO: consider re-implementing these features...
  # .option('-i, --no-icons', 'disable icons')
  # .option('-d, --no-dirs', 'disable directory serving')
  # .option('-f, --favicon <path>', 'serve the given favicon')
  .parse process.argv

  # hooks for modules to attach to
  hooks =
    beforesend: []

  # general config
  mimes =
    html: 'text/html'
    css: 'text/css'
    js: 'application/javascript'
    xml: 'text/xml'
    xsl: 'text/xsl'

  # pre-processor config
  handlers = require "./helpers/handlers"

  # default source path is cwd
  sourcepath = path.resolve program.args[0] or process.cwd()

  # setup the server
  server = express()

  for key, val of {
      exec: program.exec
      compress: program.compress
      cors: program.cors
      cache: program.cache
      livereload: program.livereload
      ## TODO: merge logs and format options
      logs: program.logs && program.format
    }
    ## TODO: pass requirements as object (mostly only needed for livereload)
    require("./helpers/#{key}")(val, server, hooks, sourcepath, handlers, mimes, program)

  sources = if program.args.length then program.args else ['.']
  served = {}
  for source in sources
    ## TODO: unify and simplify syntax for multiple doc sources, and proxy definitions
    mypaths = source.split '::'
    if mypaths and mypaths.length > 1
      myurl = mypaths.shift()
      served[myurl] = {proxy:mypaths.join('::')}
    else
      mypaths = source.split ':'
      myurl = if mypaths.length > 1 then mypaths.shift() else ''
      expandHomeDir = (mypath)->
        homedir = process.env[if process.platform == 'win32' then 'USERPROFILE' else 'HOME']
        return if !mypath then mypath
        else if mypath == '~' then homedir
        else if mypath.slice(0, 2) != '~/' then mypath
        else path.join homedir, mypath.slice 2
      do -> for mypath in mypaths
        served[myurl] = served[myurl] or {paths:[],files:[]}
        served[myurl].paths.push expandHomeDir mypath
        served[myurl].files.push fs.readdirSync path.resolve expandHomeDir mypath
  for myurl, items of served
    if items.proxy
      proxyurl = ('/'+myurl).replace(/^\/+/,'/')
      server.use proxyurl, proxy items.proxy
      console.log 'proxying ' + proxyurl + ' to ' + items.proxy
    else
      ## TODO: implement each middleware as helper, injected via hooks
      do -> for mypath in items.paths      
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
              # process str with beforesend hooks
              for cb in hooks.beforesend
                str = cb str, req, program
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

  # start the server
  server.listen program.port, ->
    console.log 'serving %s on port %d', sourcepath, program.port

module.exports = run: run
