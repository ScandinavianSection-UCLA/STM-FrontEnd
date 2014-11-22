events = require "events"
extend = require "extend"

buildInferencerIO = (socket, next) ->
  socket.on "build-inferencer/subscribe", (hash) ->
    buildInferencerIO.on hash, (message) ->
      socket.emit "build-inferencer/#{hash}", message
  next()

extend buildInferencerIO, new events.EventEmitter()

module.exports = buildInferencerIO
