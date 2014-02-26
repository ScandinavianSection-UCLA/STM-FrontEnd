express = require "express"
http = require "http"
core = require "./core"

web = express()
web.configure ->
	web.use express.compress()
	web.use express.bodyParser()
	web.use express.static "#{__dirname}/public", maxAge: 0, (err) -> console.log "Static: #{err}"
	web.set "views", "#{__dirname}/views"
	web.set "view engine", "jade"
	web.use web.router

web.get "/", (req, res) ->
	core.getTopics (err, topics) ->
		return res.send 500, error: err if err?
		res.render "index", topics: topics

web.get "/data/topicsList", (req, res, next) ->
	core.getTopicsList (err, topics) ->
		return res.jsonp 500, err if err?
		res.jsonp topics

web.get "/data/topicDetails", (req, res, next) ->
	core.getTopicDetails req.param("id"), (err, topic) ->
		return res.jsonp 500, err if err?
		res.jsonp topic

web.get "/data/article", (req, res, next) ->
	core.getArticle req.param("article_id"), (err, article) ->
		return res.jsonp 500, err if err?
		res.jsonp article

web.post "/data/renameTopic", (req, res, next) ->
	core.renameTopic req.param("id"), req.param("name"), (err, success) ->
		return res.jsonp 500, err if err?
		res.jsonp success

web.post "/data/setTopicHidden", (req, res, next) ->
	core.setTopicHidden req.param("id"), req.param("hidden"), (err, success) ->
		return res.jsonp 500, err if err?
		res.jsonp success

web.get "/data/corporaList", (req, res, next) ->
	core.getCorporaList (err, corpora) ->
		return res.jsonp 500, err if err?
		res.jsonp corpora

web.get "/data/subcorporaList", (req, res, next) ->
	core.getSubcorporaList req.param("corpus"), (err, subcorpora) ->
		return res.jsonp 500, err if err?
		res.jsonp subcorpora

web.put "/data/corpus", (req, res, next) ->
	core.insertCorpus req.param("corpus"), (err, success) ->
		return res.jsonp 500, err if err?
		res.jsonp success

web.put "/data/subcorpus", (req, res, next) ->
	core.insertSubcorpus req.param("corpus"), req.param("subcorpus"), (err, success) ->
		return res.jsonp 500, err if err?
		res.jsonp success

web.get /\/([a-z]+)/, (req, res, next) ->
	res.render req.params[0], (err, html) ->
		next() if err
		res.send html

#web.get "*", (req, res) ->
#	res.render "404"

server = http.createServer web

server.listen (port = process.env.PORT ? 5080), -> console.log "Listening on port #{port}"