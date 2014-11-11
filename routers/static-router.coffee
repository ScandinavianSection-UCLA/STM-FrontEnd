express = require "express"
path = require "path"

router = express.Router()

router.get "/bootstrap.min.css", (req, res, next) ->
  res.sendFile path.resolve __dirname,
    "../node_modules/bootstrap/dist/css/bootstrap.min.css"

router.use "/font-awesome", express.static path.resolve __dirname,
  "../node_modules/font-awesome/"

router.get "/page.css", (req, res, next) ->
  res.sendFile path.resolve __dirname, "../page.css"

module.exports = router
