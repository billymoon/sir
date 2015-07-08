#!/usr/bin/env node

process.on('uncaughtException', function (err) {
  console.log(err);
  if (err.code === 'EADDRINUSE') {
    var port = program.port ? 'port ' + program.port : 'the port';
    console.error('looks like ' + port + ' is already in use\ntry a different port with: --port <PORT>');
  } else {
    console.error(err.syscall + ' ' + err.code);
  }
});

/**
 * Module dependencies.
 */

var pather = require('path');

var resolve = require('path').resolve;
var join = require('path').join;
var exec = require('child_process').exec;
var program = require('commander');
var coffee = require('coffee-script');
var marked = require('marked');
var express = require('express');
var directory = require('../lib/directory/directory.js');
var stylus = require('stylus');
var jade = require('jade');
var less = require('less');
var url = require('url');
var fs = require('fs');
var illiterate = require('illiterate');
var slm = require('slm');
var beautify = require('js-beautify');
var compression = require('compression');
var morgan = require('morgan');

// CLI

program
  .version(require('../package.json').version)
  .usage('[options] [dir]')
  .option('-F, --format <fmt>', 'specify the log format string', 'dev')
  .option('-p, --port <port>', 'specify the port [8080]', Number, 8080)
  .option('-H, --hidden', 'enable hidden file serving')
  .option('-S, --no-stylus', 'disable stylus rendering')
  .option('-J, --no-jade', 'disable jade rendering')
  .option('    --no-less', 'disable less css rendering')
  .option('    --no-coffee', 'disable coffee script rendering')
  .option('    --no-markdown', 'disable markdown rendering')
  .option('    --no-illiterate', 'disable illiterate rendering')
  .option('    --no-slim', 'disable slim rendering')
  .option('-I, --no-icons', 'disable icons')
  .option('-L, --no-logs', 'disable request logging')
  .option('-D, --no-dirs', 'disable directory serving')
  .option('-f, --favicon <path>', 'serve the given favicon')
  .option('-C, --cors', 'allows cross origin access serving')
  .option('    --compress', 'gzip or deflate the response')
  .option('    --exec <cmd>', 'execute command on each request')
  .parse(process.argv);

// path
var path = resolve(program.args.shift() || '.');

// setup the server
var server = express();

// logger
// TODO: accept log format
// if (program.logs) server.use(morgan(morgan.compile(program.format)));
if (program.logs) server.use(morgan('dev'));

// slm template helpers

slm.template.registerEmbeddedFunction('markdown', marked);

slm.template.registerEmbeddedFunction('coffee', function (str) {
  return '<script>' + coffee.compile(str) + '</script>';
});

slm.template.registerEmbeddedFunction('less', function (str) {
  var css;
  less.render(str, function (e, compiled) { css = compiled; });
  return '<style type="text/css">' + css + '</style>';
});

slm.template.registerEmbeddedFunction('stylus', function (str) {
  return '<style type="text/css">' + stylus.render(str) + '</style>';
});

// file types for plain serving and alter-ego extension rendering
var types = {
  coffee: {
    ext: 'coffee',
    next: 'js',
    mime: 'application/javascript',
    flag: program.coffee,
    process: function (str, file) {
      return coffee.compile(str);
    }
  },
  litcoffee: {
    ext: 'coffee.md',
    next: 'js',
    mime: 'application/javascript',
    flag: program.coffee,
    process: function (str, file) {
      return coffee.compile(str, {literate: true});
    }
  },
  litjs: {
    ext: 'js.md',
    next: 'js',
    mime: 'application/javascript',
    flag: program.illiterate,
    process: function (str, file) {
      return illiterate(str);
    }
  },
  jade: {
    ext: 'jade',
    next: 'html?',
    mime: 'text/html',
    flag: program.jade,
    process: function (str, file) {
      var fn = jade.compile(str, { filename: file });
      return fn();
    }
  },
  slim: {
    ext: 'slim',
    next: 'html?',
    mime: 'text/html',
    flag: program.slim,
    process: function (str, file) {
      return beautify.html(slm.render(str), {indent_size: 4});
    }
  },
  markdown: {
    ext: 'md',
    next: 'html?',
    mime: 'text/html',
    flag: program.markdown,
    process: function (str, file) {
      return marked(str);
    }
  },
  litcoffeemd: {
    ext: 'coffee.md',
    next: 'html?',
    mime: 'text/html',
    flag: program.markdown,
    process: function (str, file) {
      return marked(str);
    }
  },
  stylus: {
    ext: 'styl',
    next: 'css',
    mime: 'text/css',
    flag: program.stylus,
    process: function (str, file) {
      return stylus.render(str);
    }
  },
  less: {
    ext: 'less',
    next: 'css',
    mime: 'text/css',
    flag: program.less,
    process: function (str, file) {
      var css;
      less.render(str, function (e, compiled) { css = compiled; });
      return css;
    }
  }
};

var setup = function (type) {
  var tech = types[type];
  server.use(function (req, res, next) {
    var rex = new RegExp('\\.' + tech.next + '$');
    if (!url.parse(req.originalUrl).pathname.match(rex)) return next();
    var file = join(path, decodeURI(url.parse(req.url).pathname));
    var rend = file.replace(rex, '.' + tech.ext);
    if (fs.existsSync(rend)) {
      fs.readFile(rend, 'utf8', function (err, str) {
        if (err) return next(err);
        try {
          str = tech.process(str, file); // custom function can use/discard args as needed
          res.setHeader('Content-Type', tech.mime);
          res.setHeader('Content-Length', Buffer.byteLength(str));
          res.end(str);
        } catch (err) {
          next(err);
        }
      });
    } else {
      // allow other handlers to have a bash at the same extension
      next();
    }
  });
  server.use(function (req, res, next) {
    var rex = new RegExp('\\.' + tech.ext + '$');
    if (!req.url.match(rex)) return next();
    var file = join(path, decodeURI(url.parse(req.url).pathname));
    if (fs.existsSync(file)) {
      fs.readFile(file, 'utf8', function (err, str) {
        if (err) return next(err);
        try {
          res.setHeader('Content-Type', 'text/plain');
          res.setHeader('Content-Length', Buffer.byteLength(str));
          res.end(str);
        } catch (err) {
          next(err);
        }
      });
    }
  });
};

// do setup for each defined renderable extension
for (var type in types) {
  if (types[type].flag) {
    setup(type);
  }
}

// CORS access for files
if (program.cors) {
  server.use(function (req, res, next) {
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET,PUT,POST,DELETE,OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization, Content-Length, X-Requested-With, Accept, x-csrf-token, origin');
    if (req.method === 'OPTIONS') return res.end();
    next();
  });
}

// compression
if (program.compress) {
  server.use(compression());
}

// exec command
if (program.exec) {
  server.use(function (req, res, next) {
    exec(program.exec, next);
  });
}

// static files
server.use(express.static(path, { hidden: program.hidden }));
server.use(express.static(__dirname + '/../lib/extra', { hidden: program.hidden }));

// directory serving

if (program.dirs) {
  server.use(directory(path, {
    hidden: program.hidden,
    icons: program.icons
  }));
  server.use(directory(__dirname + '/../lib/extra', {
    hidden: program.hidden,
    icons: program.icons
  }));
}

// start the server
server.listen(program.port, function () {
  console.log('serving %s on port %d', path, program.port);
});
