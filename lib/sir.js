const micro = require('micro')

import yargs from 'yargs'
import handlers from './handlers'
import path from 'path'

const parseRoute = arg => {
  const route = arg.indexOf(':') === -1 ? '/' : arg.slice(0, arg.indexOf(':')) + '/'
  const sources = arg.slice(arg.indexOf(':') + 1).split(',')
  return { route, sources }
}

const getOpts = () => {
  const aliases = {
    p: 'port',
    h: 'hidden',
    f: 'format'
  }

  const defaults = {
    port: 8080,
    hidden: false,
    backup: false,
    livereload: true,
    logs: true,
    format: 'dev',
    minify: false,
    compress: false,
    exec: false,
    cors: true,
    babel: false
  }

  const descriptions = {
    port: 'specify the port [8080]',
    hidden: 'enable hidden file serving',
    backup: 'store copy of each served file in `backup` folder',
    'no-livereload': 'disable livereload watching served directory (add `lr` to querystring of requested resource to inject client script)',
    'no-logs': 'disable request logging',
    format: 'specify the log format string (npmjs.com/package/morgan)',
    minify: 'minify code before serving',
    compress: 'gzip or deflate the response',
    exec: 'execute command on each request',
    'no-cors': 'disable cross origin access serving',
    babel: 'pass all js through babel to convert to more js :)'
  }

  const opts = yargs.alias(aliases).describe(descriptions).default(defaults).help('help').argv

  const { _: args, $0: bin } = opts

  opts.routes = args.map(parseRoute).sort((a, b) => a.route > b.route ? -1 : 1)
  opts.bin = bin
  delete opts._
  delete opts.$0

  Object.keys(aliases).forEach(item => delete opts[item])
  Object.keys(opts).forEach(item => item.match('-') && delete opts[item])

  return opts
}

export default () => {
  const opts = getOpts()
  console.log(opts.routes)

  micro(async (req, res) => {
    opts.routes.some(({route, sources}) => {
      if (`${req.url.slice(0, req.url.indexOf('?'))}/`.indexOf(route) === 0) {
        console.log(req.url, sources)
        return true
      }
    })
    return 'Cool'
    // return new Promise(resolve => {
    //   setTimeout(() => resolve('Hello world'), 500)
    // })
  }).listen(opts.port)

  // define main app config
  // let app = {
  //   // server: require('express')(),
  //   // program: require('commander'),
  //   hooks: { // hooks for modules to attach to
  //     beforesend: [],
  //     pathserver: []
  //   },
  //   mimes: {
  //     html: 'text/html',
  //     css: 'text/css',
  //     js: 'application/javascript',
  //     json: 'application/json',
  //     xml: 'text/xml',
  //     xsl: 'text/xsl'
  //   }
  // }

  // options and usage
  // app.program
  //   .version(require('../package').version)
  //   .usage('[options] <dir>')
  //   .option('-p, --port <port>', 'specify the port [8080]', Number, 8080)
  //   .option('-h, --hidden', 'enable hidden file serving')
  //   .option('    --backup <backup-folder>', 'store copy of each served file in `backup` folder', String, 'cache')
  //   .option('    --no-livereload', 'disable livereload watching served directory (add `lr` to querystring of requested resource to inject client script)')
  //   .option('    --no-logs', 'disable request logging')
  //   .option('-f, --format <fmt>', 'specify the log format string (npmjs.com/package/morgan)', 'dev')
  //   .option('    --minify', 'minify code before serving')
  //   .option('    --compress', 'gzip or deflate the response')
  //   .option('    --exec <cmd>', 'execute command on each request')
  //   .option('    --no-cors', 'disable cross origin access serving')
  //   .option('    --babel', 'pass all js through babel to convert to more js :)')
  //   .parse(process.argv)

  // console.log(Object.keys(app.program._events).map(item => item.slice('option:'.length)))
  // console.log(app.program.Option())
//   app.handlers = handlers(app.program) // pre-processor handlers

//   for (let helperName of [
//     'minify',
//     'preprocess',
//     'static',
//     'mime',
//     'dirlist',
//     'exec',
//     'compress',
//     'cors',
//     'backup',
//     'logs',
//     'core', // main bootstrap, requires parse and proxy
//     'livereload'
//   ]) {
//     let helper = require(`./helpers/${helperName}`).default
//     helper(app)
//   }

//   function startServer (port, cb) {
//     console.log('going to try %s', port)
//     app.server.listen(port, () => console.log('serving %s on port %d', path.resolve(app.program.args[0] || process.cwd()), port))
//   }

//   // start the server
//   startServer(app.program.port)

  // console.log(handlers(app.program))
  // console.log(path)
}
