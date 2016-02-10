module.exports = (program)->

  beautify = require 'js-beautify'

  # pre-process languages
  coffee = require 'coffee-script'
  marked = require 'marked'
  stylus = require 'stylus'
  jade = require 'jade'
  less = require 'less'
  sass = require 'node-sass'
  slm = require 'slm'
  xml2json = require 'xml2json'

  handlers =
    js:
      # only require babel if it is going to be used - takes about 1 second to load!
      process: (str)->
        if program.babel then require('babel-core').transform(str, {presets:['es2015']}).code else str
      chain: 'js'
    xml:
      process: (str)-> JSON.stringify JSON.parse(xml2json.toJson str), null, 4
      chain: 'json'
    svg:
      process: (str)-> JSON.stringify JSON.parse(xml2json.toJson str), null, 4
      chain: 'json'
    less:
      process: (str, file)-> out=null; less.render(str, {filename:file, syncImport:true}, (e, compiled)-> out=compiled); out.css
      chain: 'css'
    stylus:
      process: (str)-> stylus.render str
      chain: 'css'
    scss:
      process: (str)-> sass.renderSync(data: str).css
      chain: 'css'
    sass:
      process: (str)-> sass.renderSync(data: str, indentedSyntax: true).css
      chain: 'css'
    coffee:
      process: (str)-> coffee.compile str, bare:true
      chain: 'js'
    markdown:
      process: (str)-> beautify.html marked str
      chain: 'html'
    jade:
      process: (str, file) -> beautify.html jade.compile(str, filename: file)()
      chain: 'html'
    slim:
      process: (str) -> beautify.html slm.render(str), indent_size: 4
      chain: 'html'

  handlers.md = handlers.markdown
  handlers.slm = handlers.slim
  handlers.styl = handlers.stylus

  slm.template.registerEmbeddedFunction 'markdown', handlers.markdown.process

  slm.template.registerEmbeddedFunction 'coffee', (str) ->
    '<script>' + handlers.coffee.process(str) + '</script>'

  slm.template.registerEmbeddedFunction 'less', (str) ->
    '<style type="text/css">' + handlers.less.process(str) + '</style>'

  slm.template.registerEmbeddedFunction 'stylus', (str) ->
    '<style type="text/css">' + handlers.stylus.process(str) + '</style>'

  slm.template.registerEmbeddedFunction 'scss', (str) ->
    '<style type="text/css">' + handlers.scss.process(str) + '</style>'

  slm.template.registerEmbeddedFunction 'sass', (str) ->
    '<style type="text/css">' + handlers.sass.process(str) + '</style>'

  handlers