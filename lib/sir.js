const path = require('path')

const express = require('express')
const program = require('commander')

const handlers = require('./handlers')

module.exports = () => {
  // define main app config
  let app = {
    server: express(),
    program: program,
    hooks: { // hooks for modules to attach to
      beforesend: [],
      pathserver: []
    },
    mimes: {
      html: 'text/html',
      css: 'text/css',
      js: 'application/javascript',
      json: 'application/json',
      xml: 'text/xml',
      xsl: 'text/xsl'
    }
  }

  // options and usage
  app.program
    .version(require('../package.json').version)
    .usage('[options] <dir>')
    .option('-p, --port <port>', 'specify the port [8080]', Number, 8080)
    .option('-h, --hidden', 'enable hidden file serving')
    .option('    --backup <backup-folder>', 'store copy of each served file in `backup` folder', String)
    .option('    --no-livereload', 'disable livereload watching served directory (add `lr` to querystring of requested resource to inject client script)')
    .option('    --no-logs', 'disable request logging')
    .option('-f, --format <fmt>', 'specify the log format string (npmjs.com/package/morgan)', 'dev')
    .option('    --minify', 'minify code before serving')
    .option('    --compress', 'gzip or deflate the response')
    .option('    --exec <cmd>', 'execute command on each request')
    .option('    --no-cors', 'disable cross origin access serving')
    .option('    --babel', 'pass all js through babel to convert to more js :)')
    .parse(process.argv)

  app.handlers = handlers(app.program) // pre-processor handlers

  for (let helperName of [
    'minify',
    'preprocess',
    'static',
    'mime',
    'dirlist',
    'exec',
    'compress',
    'cors',
    'backup',
    'logs',
    'core', // main bootstrap, requires parse and proxy
    'livereload'
  ]) {
    let helper = require(`./helpers/${helperName}`)
    helper(app)
  }

  function startServer (port, cb) {
    console.log('going to try %s', port)
    app.server.listen(port, () => console.log('serving %s on port %d', path.resolve(app.program.args[0] || process.cwd()), port))
  }

  // start the server
  startServer(app.program.port)
}

