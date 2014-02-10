express = require "express"
http = require "http"

web = express()
web.configure ->
	web.use express.compress()
	web.use express.bodyParser()
	web.use express.static "#{__dirname}/public", maxAge: 0, (err) -> console.log "Static: #{err}"
	web.set "views", "#{__dirname}/views"
	web.set "view engine", "jade"
	web.use web.router

web.get "/", (req, res) ->
	res.render "index"

web.get "/roms", (req, res) ->
	res.render "roms", availableRegions: core.getAvailableRegions()

web.get "/latestROMS.json", (req, res) ->
	res.jsonp core.getLatestROMS()

web.get /\/([a-z]+)/, (req, res, next) ->
	res.render req.params[0], (err, html) ->
		next() if err
		res.send html

web.get "*", (req, res) ->
	res.render "404"

server = http.createServer web

server.listen (port = process.env.PORT ? 5080), -> console.log "Listening on port #{port}"