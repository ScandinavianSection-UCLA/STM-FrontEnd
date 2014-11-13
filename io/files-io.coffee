events = require "events"
extend = require "extend"

filesIO = (socket, next) ->
  socket.on "files/subscribe", (hash, callback) ->
    filesIO.on hash, callback

extend filesIO, new events.EventEmitter()

module.exports = filesIO
