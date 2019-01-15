const proxy = require('proxy-middleware')

module.exports = function (app, data) {
  let proxyurl = ('/' + data.myurl).replace(/^\/+/, '/')
  app.server.use(proxyurl, proxy(data.mypath))
  console.log(`proxying ${proxyurl} to ${data.mypath}`)
}
