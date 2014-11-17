events = require "events"
extend = require "extend"

filesIO = (socket, next) ->
  socket.on "files/subscribe", (hash) ->
    filesIO.on hash, (message) ->
      socket.emit "files/#{hash}", message
  next()

extend filesIO, new events.EventEmitter()

module.exports = filesIO
