beautify = require 'js-beautify'

# pre-process languages
coffee = require 'coffee-script'
marked = require 'marked'
stylus = require 'stylus'
jade = require 'jade'
less = require 'less'
sass = require 'node-sass'
slm = require 'slm'
mustache = require 'mustache'

handlers =
  less:
    process: (str)-> css=null; less.render(str, (e, compiled)-> css=compiled); css
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
  ## TODO: better way to handle xml and xsl in slim - perhaps double barrel name?
  xmls:
    process: (str) -> beautify.html slm.render(str), indent_size: 4
    chain: 'xml'
  xslm:
    process: (str) -> beautify.html slm.render(str), indent_size: 4
    chain: 'xsl'

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

module.exports = handlers