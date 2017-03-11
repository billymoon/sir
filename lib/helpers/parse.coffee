fs = require 'fs'
path = require 'path'

expandHomeDir = (mypath)->
  homedir = process.env[if process.platform == 'win32' then 'USERPROFILE' else 'HOME']
  return if !mypath then mypath
  else if mypath == '~' then homedir
  else if mypath.slice(0, 2) != '~/' then mypath
  else path.join homedir, mypath.slice 2

module.exports = (app)->
  served = {}
  sources = if app.program.args.length then app.program.args else ['.']
  # TODO: perhaps better test required to see if there is a folder specified to serve
  if !sources.reduce ((memo,item)-> memo = true if !/:/.test item; return memo), false
    sources.push '.'
  for source in sources
    proxy_source = null
    source = source.replace /:(https?:\/\/.+)$/, (all, m1)-> proxy_source = m1; ''
    mypaths = source.split ':'
    if mypaths[0]
      if proxy_source
        served[source] = proxy: proxy_source
      else
        myurl = if mypaths.length > 1 then mypaths.shift() else ''
        do -> for mypath in mypaths
          served[myurl] = served[myurl] or {paths:[],files:[]}
          served[myurl].paths.push expandHomeDir mypath
          try
            served[myurl].files.push fs.readdirSync path.resolve expandHomeDir mypath
  served