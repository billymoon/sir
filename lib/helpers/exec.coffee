exec = require('child_process').exec

module.exports = (command, server)->
  if command
    server.use (req, res, next) ->
      exec command, next
