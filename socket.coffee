io = require "socket.io-client"

module.exports = io.connect() if typeof window isnt "undefined"
