socketIO = require "socket.io"

{server} = require "./server"

io = socketIO.listen server
io.set "log level", 0
io.sockets.on "connection", (socket) ->
  socket.on "subscribe", (hash) ->
    socket.join hash

module.exports = io
