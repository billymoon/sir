const fs = require('fs')
const path = require('path')

const parsePath = pathString => {
  let type
  let files

  if (/^https?:\/\//.test(pathString)) {
    type = 'proxy'
  } else if (fs.statSync(pathString).isDirectory()) {
    type = 'dir'
    files = fs.readdirSync(path.resolve(expandHomeDir(pathString)))
  } else if (pathString.slice(-3) === '.js' && fs.statSync(pathString).isFile()) {
    type = 'js'
  }

  return {
    type,
    files,
    location: pathString
  }
}

let expandHomeDir = function (mypath) {
  let homedir = process.env[process.platform === 'win32' ? 'USERPROFILE' : 'HOME']
  return !mypath ? mypath
  : mypath === '~' ? homedir
  : mypath.slice(0, 2) !== '~/' ? mypath
  : path.join(homedir, mypath.slice(2))
}

module.exports = function (app) {
  let sources = app.program.args.length ? app.program.args : ['.']

  const sourcesMapped = sources.map(source => {
    let mapped

    const sepIndex = source.indexOf(':')

    if (sepIndex !== -1) {
      mapped = parsePath(source.slice(sepIndex + 1))
      mapped.route = source.slice(0, sepIndex)
    } else {
      mapped = parsePath(source)
      mapped.route = ''
    }
    return mapped
  })

  if (!sourcesMapped.filter(item => item.type === 'dir').length) {
    sourcesMapped.push(parsePath('.'))
  }

  // TODO: return soucesMapped, refactor consumer
  const served = sourcesMapped.reduce((memo, item) => {
    if (item.type === 'proxy') {
      memo[item.route] = { proxy: item }
    } else if (item.type === 'dir') {
      memo[item.route] = memo[item.route] || { paths: [], files: [] }
      memo[item.route].paths.push(item.location)
      memo[item.route].files.push(item.files)
    }
    return memo
  }, {})

  return served
}
