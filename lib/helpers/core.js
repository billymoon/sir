const proxy = require('./proxy')
const parse = require('./parse')

module.exports = function (app) {
  const served = parse(app.program.args)

  for (var myurl in served) {
    var items = served[myurl]
    if (items.proxy) {
      proxy(app, { mypath: items.proxy.location, myurl })
    } else if (items.middleware) {
      app.server.use(myurl, require(items.middleware))
    } else {
      Array.from(items.paths).map(mypath => Array.from(app.hooks.pathserver).map(fn => fn({ mypath, myurl })))
    }
  }
}
