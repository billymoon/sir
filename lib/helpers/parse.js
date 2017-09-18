const fs = require('fs')
const path = require('path')

let expandHomeDir = function (mypath) {
  let homedir = process.env[process.platform === 'win32' ? 'USERPROFILE' : 'HOME']
  return !mypath ? mypath
  : mypath === '~' ? homedir
  : mypath.slice(0, 2) !== '~/' ? mypath
  : path.join(homedir, mypath.slice(2))
}

module.exports = function (app) {
  let served = {}
  let sources = app.program.args.length ? app.program.args : ['.']
  // TODO: perhaps better test required to see if there is a folder specified to serve
  if (!sources.reduce(function (memo, item) { if (!/:/.test(item)) { memo = true; return memo } }, false)) {
    sources.push('.')
  }
  for (let source of Array.from(sources)) {
    let proxySource = null
    source = source.replace(/:(https?:\/\/.+)$/, function (all, m1) { proxySource = m1; return '' })
    var mypaths = source.split(':')
    if (mypaths[0]) {
      if (proxySource) {
        served[source] = {proxy: proxySource}
      } else {
        var myurl = mypaths.length > 1 ? mypaths.shift() : ''
        Array.from(mypaths).map(mypath => {
          served[myurl] = served[myurl] || {paths: [], files: []}
          served[myurl].paths.push(expandHomeDir(mypath))
          try {
            served[myurl].files.push(fs.readdirSync(path.resolve(expandHomeDir(mypath))))
          } catch (error) {}
        })
      }
    }
  }
  return served
}
