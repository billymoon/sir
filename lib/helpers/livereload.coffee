path = require 'path'
tinylr = require 'tiny-lr'
watchr = require 'watchr'
cheerio = require 'cheerio'
request = require 'request'

module.exports = (app)->
  # livereload (add ?lr to url to activate - watches served paths)
  if app.program.livereload

    # process lr to add livereload script to page
    app.hooks.beforesend.push (str, req)->
      if req.query.lr?
        lr_tag = """
        <script src="/livereload.js?snipver=1"></script>\n
        """
        $ = cheerio.load str
        if $('script').length
          $('script').before lr_tag
          str = $.html()
        else
          str = lr_tag + str
      str

    app.server.use tinylr.middleware app: app.server
    watchr.watch
      path: path.resolve app.program.args[0] or process.cwd()
      catchupDelay: 200
      listeners:
        change: (type, filename)-> # additional arguments: currentStat and originalStat
          m = filename.match /\.([^.]+)$/
          extension = m?[1]
          if !!extension and (app.handlers[extension] or app.mimes[extension])
            served_filename = filename.replace RegExp("#{m[1]}$"), app.handlers[extension]?.chain or extension
            request "http://127.0.0.1:#{app.program.port}/changed?files="+served_filename, (error, response, body)->
              console.log 'livereloaded due to change: ' + filename
