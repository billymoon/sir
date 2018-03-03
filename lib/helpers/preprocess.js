const _ = require('lodash')
const fs = require('fs')
const path = require('path')
const illiterate = require('illiterate')

module.exports = function (app) {
  let virtuallyIlliterate = {}

  app.hooks.pathserver.push(data =>

    app.server.use(function (req, res, next) {
      let fallthrough = true

      _.each(_.keys(app.handlers), function (item, index) {
        // TODO: safe alternative to `req._parsedUrl`
        let replacedPath = req._parsedUrl.pathname.replace(new RegExp(`^/?${data.myurl}`), '')
        let m = replacedPath.match(new RegExp(`^/?(.+)\\.${(app.handlers[item] != null ? app.handlers[item].chain : undefined)}$`))
        let literatePath = `${replacedPath}.md`.replace(/^\//, '')
        let compilablePath = !!m && `${m[1]}.${item}`
        let literateCompilablePath = !!m && `${m[1]}.${item}.md`
        let literate = null
        let raw = null
        let checkpath = pathToCheck => fs.existsSync(path.resolve(path.join(data.mypath, pathToCheck)))

        if (!!fallthrough && (
            (checkpath(literatePath) && (literate = true && (raw = true))) ||
            (!!m && (checkpath(compilablePath) || (checkpath(literateCompilablePath) && (literate = true))))
          )) {
          let literateMime
          fallthrough = false
          let currentpath = raw ? literatePath : literate ? literateCompilablePath : compilablePath
          currentpath = path.join(data.mypath, currentpath)
          let str = fs.readFileSync(path.resolve(currentpath)).toString('UTF-8')

          if (literate) {
            let illiterated = illiterate(str)
            _.each(illiterated, function (item) { virtuallyIlliterate[path.normalize(path.join(path.dirname(req._parsedUrl.pathname), item.filename))] = item.content })
            str = illiterated.default
          }

          if (!raw) { str = app.handlers[item].process(str, path.resolve(currentpath)) }
          // process str with beforesend hooks
          for (let cb of Array.from(app.hooks.beforesend)) {
            str = cb(str, req, app.program)
          }

          if (!!literate && !!raw) {
            let part = path.extname(replacedPath).replace(/^\./, '')
            // TODO: perhaps use filetype for mime instead of plain ... #{part or 'plain'}"
            literateMime = app.mimes[part] ? app.mimes[part] : 'text/plain'
          }

          res.set('Content-Type', literateMime ? `${literateMime}; charset=utf-8` : raw ? `text/${item}; charset=utf-8` : `${app.mimes[app.handlers[item] != null ? app.handlers[item].chain : undefined]}; charset=utf-8`)
          res.set('Content-Length', Buffer.byteLength(str, 'utf-8'))
          res.end(str)
        }
      })

      if (!!fallthrough && !!virtuallyIlliterate[path.normalize(req._parsedUrl.pathname)]) {
        fallthrough = false

        res.set('Content-Type', `${app.mimes[path.extname(req._parsedUrl.pathname).slice(1)] || (`text/${path.extname(req._parsedUrl.pathname).slice(1)}`)}; charset=utf-8`)
        res.set('Content-Length', Buffer.byteLength(virtuallyIlliterate[path.normalize(req._parsedUrl.pathname)], 'utf-8'))
        res.end(virtuallyIlliterate[path.normalize(req._parsedUrl.pathname)])
      }

      if (fallthrough) { next() }
    })
  )
}
