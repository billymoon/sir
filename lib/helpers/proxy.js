const url = require('url');
const proxy = require('proxy-middleware')

module.exports = function (app, data) {
  const proxyurl = ('/' + data.myurl).replace(/^\/+/, '/')
  const config = url.parse(data.mypath)
  if (app.program.agent) {
    config.headers = config.headers || {}
    config.headers['User-Agent'] = app.program.agent;
  }
  app.server.use(proxyurl, proxy(config))
  console.log(`proxying ${proxyurl} to ${data.mypath}`)
}
