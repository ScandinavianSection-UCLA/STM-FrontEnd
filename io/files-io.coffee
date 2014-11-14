events = require "events"
extend = require "extend"

filesIO = (socket, next) ->
  socket.on "files/subscribe", (hash) ->
    filesIO.on hash, (result) ->
      socket.emit "files/#{hash}", result
  next()

extend filesIO, new events.EventEmitter()

module.exports = filesIO
