module.exports = function (program) {
  // pre-process languages
  let marked = require('marked')
  let stylus = require('stylus')
  let less = require('less')
  let slm = require('slm')

  let handlers = {
    js: {
      // only require babel if it is going to be used - takes about 1 second to load!
      process: str => program.babel ? require('babel-core').transform(str, { presets: ['env'], 'plugins': ['transform-react-jsx'] }).code : str,
      chain: 'js'
    },
    less: {
      process: (str, file) => {
        let out = null
        less.render(str, {
          filename: file,
          syncImport: true
        }, function (e, compiled) {
          out = compiled
        })
        return out.css
      },
      chain: 'css'
    },
    stylus: {
      process: str => stylus.render(str),
      chain: 'css'
    },
    markdown: {
      process: str => marked(str),
      chain: 'html'
    },
    slim: {
      process: str => slm.render(str),
      chain: 'html'
    }
  }

  handlers.md = handlers.markdown
  handlers.slm = handlers.slim
  handlers.styl = handlers.stylus

  slm.template.registerEmbeddedFunction('markdown', handlers.markdown.process)
  slm.template.registerEmbeddedFunction('less', str => `<style type="text/css">${handlers.less.process(str)}</style>`)
  slm.template.registerEmbeddedFunction('stylus', str => `<style type="text/css">${handlers.stylus.process(str)}</style>`)

  return handlers
}
