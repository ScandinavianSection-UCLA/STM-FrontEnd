require "coffee-react/register"

bodyParser = require "body-parser"
bundlesRouter = require "./routers/bundles-router"
compression = require "compression"
dataRouter = require "./async-calls/metadata"
express = require "express"
http = require "http"
React = require "react"
rootViewsRouter = require "./routers/root-views-router"
staticRouter = require "./routers/static-router"
socketIO = require "socket.io"

router = express()

router.use compression()
router.use bodyParser.json()
router.use bodyParser.urlencoded extended: true
router.use rootViewsRouter
router.use "/static", staticRouter
router.use "/bundles", bundlesRouter
router.use dataRouter.router express: express, bodyParser: bodyParser

server = http.createServer router

server.listen (port = process.env.PORT ? 5080), ->
  console.log "Listening on port #{port}"
