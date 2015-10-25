_ = require 'lodash'
fs = require 'fs'
path = require 'path'
illiterate = require 'illiterate'

module.exports = (app)->
  app.hooks.pathserver.push (data)->
    app.server.use (req, res, next)->
      fallthrough = true
      _.each _.keys(app.handlers), (item, index)->
        ## TODO: safe alternative to `req._parsedUrl`
        replaced_path = req._parsedUrl.pathname.replace new RegExp("^\/?#{data.myurl}"), ""
        m = replaced_path.match new RegExp "^/?(.+)\\.#{app.handlers[item]?.chain}$"
        literate_path = "#{replaced_path}.md".replace(/^\//,'')
        compilable_path = !!m and "#{m[1]}.#{item}"
        literate_compilable_path = !!m and "#{m[1]}.#{item}.md"
        literate = null
        raw = null
        if !!fallthrough and (
            (fs.existsSync(path.resolve(path.join(data.mypath,literate_path))) and literate = true and raw = true) or !!m and (
              fs.existsSync(path.resolve(path.join(data.mypath,compilable_path))) or (
                fs.existsSync(path.resolve(path.join(data.mypath,literate_compilable_path))) and literate = true
              )
            )
          )
          fallthrough = false
          currentpath = if !!raw then literate_path else if literate then literate_compilable_path else compilable_path
          currentpath = path.join data.mypath, currentpath
          str = fs.readFileSync(path.resolve currentpath).toString 'UTF-8'
          if !!literate then str = illiterate str
          if not raw then str = app.handlers[item].process str, path.resolve currentpath
          # process str with beforesend hooks
          for cb in app.hooks.beforesend
            str = cb str, req, app.program
          if !!literate and !!raw
            part = path.extname(replaced_path).replace(/^\./, '')
            ## TODO: perhaps use filetype for mime instead of plain ... #{part or 'plain'}"
            literate_mime = if app.mimes[part] then app.mimes[part] else "text/plain"
          res.setHeader 'Content-Type', if !!literate_mime then "#{literate_mime}; charset=utf-8" else if !!raw then "text/#{item}; charset=utf-8" else "#{app.mimes[app.handlers[item]?.chain]}; charset=utf-8"
          res.setHeader 'Content-Length', str.length
          res.end str
      next() if fallthrough