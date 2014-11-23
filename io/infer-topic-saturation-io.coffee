events = require "events"
extend = require "extend"

inferTopicSaturationIO = (socket, next) ->
  socket.on "infer-topic-saturation/subscribe", (hash) ->
    inferTopicSaturationIO.on hash, (message) ->
      socket.emit "infer-topic-saturation/#{hash}", message
  next()

extend inferTopicSaturationIO, new events.EventEmitter()

module.exports = inferTopicSaturationIO
