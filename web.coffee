require "coffee-react/register"

bodyParser = require "body-parser"
bundlesRouter = require "./routers/bundles-router"
compression = require "compression"
corpusCalls = require "./async-calls/corpus"
express = require "express"
ingestedCorpusCalls = require "./async-calls/ingested-corpus"
filesCalls = require "./async-calls/files"
filesIO = require "./io/files-io"
filesRouter = require "./routers/files-router"
http = require "http"
nop = require "nop"
React = require "react"
rootViewsRouter = require "./routers/root-views-router"
staticRouter = require "./routers/static-router"
socketIO = require "socket.io"

router = express()

router.use compression()
router.use rootViewsRouter
router.use "/static", staticRouter
router.use "/bundles", bundlesRouter
router.use corpusCalls.router express: express, bodyParser: bodyParser
router.use filesCalls.router express: express, bodyParser: bodyParser
router.use ingestedCorpusCalls.router express: express, bodyParser: bodyParser
router.use "/files", filesRouter

server = http.createServer router

io = socketIO server

io.use filesIO

io.on "connection", nop

server.listen (port = process.env.PORT ? 5080), ->
  console.log "Listening on port #{port}"
