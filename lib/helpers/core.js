const proxymod = require('./proxy')
const parse = require('./parse')

module.exports = function (app) {
  let served = parse(app)
  let result = []
  for (var myurl in served) {
    var items = served[myurl]
    if (items.proxy) {
      result.push(proxymod(app, { mypath: items.proxy, myurl }))
    } else {
      result.push(Array.from(items.paths).map(mypath => Array.from(app.hooks.pathserver).map(cb => cb({ mypath, myurl }))))
    }
  }
  return result
}
