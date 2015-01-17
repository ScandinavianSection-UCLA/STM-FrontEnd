require "coffee-react/register"

bodyParser = require "body-parser"
browseArticlesCalls = require "./async-calls/browse-articles"
browseTopicsCalls = require "./async-calls/browse-topics"
buildInferencerIO = require "./io/build-inferencer-io"
bundlesRouter = require "./routers/bundles-router"
compression = require "compression"
corpusCalls = require "./async-calls/corpus"
express = require "express"
inferTopicSaturationIO = require "./io/infer-topic-saturation-io"
ingestedCorpusCalls = require "./async-calls/ingested-corpus"
ingestIO = require "./io/ingest-io"
filesCalls = require "./async-calls/files"
filesIO = require "./io/files-io"
filesRouter = require "./routers/files-router"
graphNodesCalls = require "./async-calls/graph-nodes"
http = require "http"
nop = require "nop"
processCorpusCalls = require "./async-calls/process-corpus"
React = require "react"
rootViewsRouter = require "./routers/root-views-router"
staticRouter = require "./routers/static-router"
socketIO = require "socket.io"
topicModelingCalls = require "./async-calls/topic-modeling"

{simulateBadLatency} = require "./constants"

router = express()

if simulateBadLatency
  router.use (req, res, next) ->
    setTimeout next, Math.random() * 1000 + 200

router.use (req, res, next) ->
  res.setTimeout 0
  next()

router.use compression()
router.use rootViewsRouter
router.use "/static", staticRouter
router.use "/bundles", bundlesRouter
router.use corpusCalls.router express: express, bodyParser: bodyParser
router.use filesCalls.router express: express, bodyParser: bodyParser
router.use ingestedCorpusCalls.router express: express, bodyParser: bodyParser
router.use "/files", filesRouter
router.use processCorpusCalls.router express: express, bodyParser: bodyParser
router.use topicModelingCalls.router express: express, bodyParser: bodyParser
router.use browseTopicsCalls.router express: express, bodyParser: bodyParser
router.use browseArticlesCalls.router express: express, bodyParser: bodyParser
router.use graphNodesCalls.router express: express, bodyParser: bodyParser

server = http.createServer router

io = socketIO server

io.use filesIO
io.use ingestIO
io.use buildInferencerIO
io.use inferTopicSaturationIO

io.on "connection", nop

server.listen (port = process.env.PORT ? 5080), ->
  console.log "Listening on port #{port}"
