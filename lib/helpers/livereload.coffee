tinylr = require 'tiny-lr'
watchr = require 'watchr'
cheerio = require 'cheerio'
request = require 'request'

module.exports = (livereload, server, hooks, sourcepath, handlers, mimes, program)->
  # livereload (add ?lr to url to activate - watches served paths)
  if livereload

    # process lr to add livereload script to page
    hooks.beforesend.push (str, req, program)->
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

    server.use tinylr.middleware app: server
    watchr.watch
      path: sourcepath
      catchupDelay: 200
      listeners:
        change: (type, filename)-> # additional arguments: currentStat and originalStat
          m = filename.match /\.([^.]+)$/
          extension = m?[1]
          if !!extension and (handlers[extension] or mimes[extension])
            served_filename = filename.replace RegExp("#{m[1]}$"), handlers[extension]?.chain or extension
            request "http://127.0.0.1:#{program.port}/changed?files="+served_filename, (error, response, body)->
              console.log 'livereloaded due to change: ' + filename
