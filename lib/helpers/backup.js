const fs = require('fs')
const path = require('path')
const mkdirp = require('mkdirp')
const zlib = require('zlib')

module.exports = function (app) {
  // http://stackoverflow.com/a/19215370/665261
  app.server.use(function (req, res, next) {
    let oldWrite = res.write
    let oldEnd = res.end

    let chunks = []

    res.write = function (chunk) {
      chunks.push(chunk)
      return oldWrite.apply(res, arguments)
    }

    res.end = function (chunk) {
      let body
      if (chunk) { chunks.push(chunk) }

      // TODO: figure out why chunks are sometimes string and sometimes buffer
      if (typeof chunks[0] === 'string') {
        body = chunks.join('')
      } else {
        body = Buffer.concat(chunks)
      }

      let filepath = req.originalUrl
      if (app.program.backup && (res.statusCode >= 200) && (res.statusCode < 400)) {
        let resolvedpath = path.resolve(path.join(app.program.backup, path.dirname(filepath)))
        let filename = path.resolve(path.join(app.program.backup, filepath))
        if (fs.existsSync(resolvedpath) && fs.lstatSync(resolvedpath).isFile()) {
          fs.renameSync(resolvedpath, resolvedpath + '.tmp')
          mkdirp.sync(resolvedpath)
          fs.renameSync(resolvedpath + '.tmp', path.join(resolvedpath, 'auto-index.html'))
        } else if (fs.existsSync(filename) && fs.lstatSync(filename).isDirectory()) {
          filename = path.join(filename, 'auto-index.html')
        } else {
          mkdirp.sync(resolvedpath)
        }

        // if body is gzipped, unzip before saving to filesystem
        if (res._headers['content-encoding'] === 'gzip') {
          body = zlib.gunzipSync(body)
        }

        fs.writeFileSync(filename, body)
      }

      oldEnd.apply(res, arguments)
    }

    next()
  })
}
