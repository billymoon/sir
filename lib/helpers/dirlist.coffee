_ = require 'lodash'
fs = require 'fs'
serveIndex = require 'serve-index'
mustache = require 'mustache'

module.exports = (app, data)->
  app.server.use "/#{data.myurl}", serveIndex data.mypath,
    'icons': false
    template: (locals, callback)->
      files = []
      dirs = []
      ## TODO: use combined file list, not just one folder
      # filelist = items.files.map (file)-> name: file
      # console.log served[data.myurl]
      _.each locals.fileList, (file, i)->
        fileobject = generated:[], a:file.name, href:locals.directory.replace(/\/$/,'')+'/'+file.name
        extstr = file.name.match /(?:\.([^.]+))?\.([^.]+)$/
        if extstr
          ext = extstr[2]
          if app.handlers[ext]?.chain
            fileobject.generated.push a:app.handlers[ext].chain, href:fileobject.href.replace /[^.]+$/, app.handlers[ext].chain
          ext = extstr[1]
          if !!ext
            if app.handlers[ext]?.chain
              fileobject.generated.push a:ext, href:fileobject.href.replace /\.[^.]+$/, ''
              fileobject.generated.push a:app.handlers[ext].chain, href:fileobject.href.replace /[^.]+\.[^.]+$/, app.handlers[ext].chain
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