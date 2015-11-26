path = require 'path'
tinylr = require 'tiny-lr'
cheerio = require 'cheerio'
request = require 'request'
watch = require 'node-watch'

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
          $('script').eq(0).before lr_tag
          str = $.html()
        else
          str = lr_tag + str
      str

    app.server.use tinylr.middleware app: app.server
    
    # would have preferred to use https://www.npmjs.com/package/watchr but breaks on node v0.10.3
    # this method has serious caveats: https://nodejs.org/api/fs.html#fs_caveats
    # The recursive option is only supported on OS X and Windows.
    # Should probably use fs.watchFile as fallback method
    watch path.resolve(app.program.args[0] or process.cwd()), (filename)->
      m = filename.match /\.([^.]+)$/
      extension = m?[1]
      if !!extension and (app.handlers[extension] or app.mimes[extension])
        served_filename = filename.replace RegExp("#{m[1]}$"), app.handlers[extension]?.chain or extension
        request "http://127.0.0.1:#{app.program.port}/changed?files="+served_filename, (error, response, body)->
          console.log 'livereloaded due to change: ' + filename
