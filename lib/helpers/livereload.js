import path from 'path'
import tinylr from 'tiny-lr'
import cheerio from 'cheerio'
import request from 'request'
import watch from 'node-watch'

export default function (app) {
  // livereload (add ?lr to url to activate - watches served paths)
  if (app.program.livereload) {
    // process lr to add livereload script to page
    app.hooks.beforesend.push(function (str, req) {
      if (req.query.lr != null) {
        let lrTag = `\
<script src="/livereload.js?snipver=1"></script>
`
        let $ = cheerio.load(str)
        if ($('script').length) {
          $('script').eq(0).before(lrTag)
          str = $.html()
        } else {
          str = lrTag + str
        }
      }
      return str
    })

    app.server.use(tinylr.middleware({app: app.server}))

    // would have preferred to use https://www.npmjs.com/package/watchr but breaks on node v0.10.3
    // this method has serious caveats: https://nodejs.org/api/fs.html#fs_caveats
    // The recursive option is only supported on OS X and Windows.
    // Should probably use fs.watchFile as fallback method
    watch(path.resolve(app.program.args[0] || process.cwd()), function (filename) {
      let m = filename.match(/\.([^.]+)$/)
      let extension = m != null ? m[1] : undefined
      if (!!extension && (app.handlers[extension] || app.mimes[extension])) {
        let servedFilename = filename.replace(RegExp(`${m[1]}$`), (app.handlers[extension] != null ? app.handlers[extension].chain : undefined) || extension)
        request(`http://127.0.0.1:${app.program.port}/changed?files=` + servedFilename, (e, response, body) => console.log(`livereloaded due to change: ${filename}`))
      }
    })
  }
}
