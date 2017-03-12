module.exports = (program)->

  beautify = require 'js-beautify'

  # pre-process languages
  marked = require 'marked'
  stylus = require 'stylus'
  less = require 'less'
  slm = require 'slm'

  handlers =
    js:
      # only require babel if it is going to be used - takes about 1 second to load!
      process: (str)->
        if program.babel then require('babel-core').transform(str, {presets:['es2015']}).code else str
      chain: 'js'
    less:
      process: (str, file)-> out=null; less.render(str, {filename:file, syncImport:true}, (e, compiled)-> out=compiled); out.css
      chain: 'css'
    stylus:
      process: (str)-> stylus.render str
      chain: 'css'
    markdown:
      process: (str)-> beautify.html marked str
      chain: 'html'
    slim:
      process: (str) -> beautify.html slm.render(str), indent_size: 4
      chain: 'html'

  handlers.md = handlers.markdown
  handlers.slm = handlers.slim
  handlers.styl = handlers.stylus

  slm.template.registerEmbeddedFunction 'markdown', handlers.markdown.process

  slm.template.registerEmbeddedFunction 'less', (str) ->
    '<style type="text/css">' + handlers.less.process(str) + '</style>'

  slm.template.registerEmbeddedFunction 'stylus', (str) ->
    '<style type="text/css">' + handlers.stylus.process(str) + '</style>'

  handlers