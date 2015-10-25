module.exports = (app)->
  parse = require './parse'
  served = parse app
  for myurl, items of served
    if items.proxy
      proxymod = require './proxy'
      proxymod app, mypath: items.proxy, myurl: myurl
    else
      do -> for mypath in items.paths
        for cb in app.hooks.pathserver
          cb mypath: mypath, myurl: myurl