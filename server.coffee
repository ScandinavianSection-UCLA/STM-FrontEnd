express = require "express"
http = require "http"

router = express()
server = http.createServer router

server.listen (port = process.env.PORT ? 5080), ->
  console.log "Listening on port #{port}"

module.exports =
  router: router
  server: server
