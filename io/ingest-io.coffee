events = require "events"
extend = require "extend"

ingestIO = (socket, next) ->
  socket.on "ingest/subscribe", (hash) ->
    ingestIO.on hash, (message) ->
      socket.emit "ingest/#{hash}", message
  next()

extend ingestIO, new events.EventEmitter()

module.exports = ingestIO
