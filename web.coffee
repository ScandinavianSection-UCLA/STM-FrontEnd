express = require "express"
http = require "http"
core = require "./core"
request = require "request"
socketIO = require "socket.io"
# longjohn = require "longjohn"

web = express()
web.configure ->
	web.use express.compress()
	web.use express.bodyParser()
	web.use express.static "#{__dirname}/public", maxAge: 0, (err) -> console.log "Static: #{err}"
	web.set "views", "#{__dirname}/views"
	web.set "view engine", "jade"
	web.use web.router

web.get "/", (req, res) ->
	res.redirect "/topics"

web.get "/data/topicsList", (req, res, next) ->
	core.getTopicsList
		corpus: req.param "corpus"
		(err, topics) ->
			return res.jsonp 500, err if err?
			res.jsonp topics

web.get "/data/topicDetails", (req, res, next) ->
	core.getTopicDetails
		corpus: req.param "corpus"
		subcorpus: req.param "subcorpus"
		topic_id: req.param "id"
		(err, topic) ->
			return res.jsonp 500, err if err?
			res.jsonp topic

web.get "/data/article", (req, res, next) ->
	core.getArticle
		corpus: req.param "corpus"
		subcorpus: req.param "subcorpus"
		article_id: req.param "article_id"
		(err, article) ->
			return res.jsonp 500, err if err?
			res.jsonp article

web.post "/data/renameTopic", (req, res, next) ->
	core.renameTopic
		corpus: req.param "corpus"
		subcorpus: req.param "subcorpus"
		topic_id: req.param "id"
		new_name: req.param "name"
		(err, success) ->
			return res.jsonp 500, err if err?
			res.jsonp success

web.post "/data/setTopicHidden", (req, res, next) ->
	core.setTopicHidden
		corpus: req.param "corpus"
		subcorpus: req.param "subcorpus"
		topic_id: req.param "id"
		hidden_flag: req.param("hidden") is "true"
		(err, success) ->
			return res.jsonp 500, err if err?
			res.jsonp success

web.get "/data/corporaList", (req, res, next) ->
	core.getCorporaList
		processedOnly: req.param("processedOnly") is "true"
		(err, corpora) ->
			return res.jsonp 500, err if err?
			res.jsonp corpora

web.get "/data/subcorporaList", (req, res, next) ->
	core.getSubcorporaList
		corpus: req.param "corpus"
		processedOnly: req.param("processedOnly") is "true"
		(err, subcorpora) ->
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

web.post "/data/file", (req, res, next) ->
	core.addFile req.files.file, req.param("corpus"), req.param("subcorpus"), (err, response) ->
		return res.jsonp 500, err if err?
		if response.success
			res.jsonp response
		else if response.extractor?
			res.jsonp status: "extracting", hash: response.extractor.hash
			response.extractor.on "progress", (progress) ->
				io.sockets.in(response.extractor.hash).volatile.emit response.extractor.hash, "progress", progress
			response.extractor.on "extracted", ->
				io.sockets.in(response.extractor.hash).emit response.extractor.hash, "extracted"
			response.extractor.on "completed", ->
				io.sockets.in(response.extractor.hash).emit response.extractor.hash, "completed"
		else
			res.jsonp response

web.get "/data/filesList", (req, res, next) ->
	core.getFilesList req.param("corpus"), req.param("subcorpus"), Number(req.param "from") ? 0, (err, result) ->
		return res.jsonp 500, err if err?
		res.jsonp result

web.post "/data/startTopicModeling", (req, res, next) ->
	core.processTopicModeling req.param("corpus"), req.param("subcorpus"), Number(req.param "num_topics") ? 0, (err, response) ->
		return res.jsonp 500, err if err?
		if response.success
			res.jsonp success: true, status: "processingIngestChunks", hash: response.statusEmitter.hash
			console.log "Hash: #{response.statusEmitter.hash}"
			response.statusEmitter.on "processingTrainTopics", ->
				io.sockets.in(response.statusEmitter.hash).emit response.statusEmitter.hash, "processingTrainTopics"
				console.log "Hash: #{response.statusEmitter.hash}, Status: processingTrainTopics"
			response.statusEmitter.on "processingInferTopics", ->
				io.sockets.in(response.statusEmitter.hash).emit response.statusEmitter.hash, "processingInferTopics"
				console.log "Hash: #{response.statusEmitter.hash}, Status: processingInferTopics"
			response.statusEmitter.on "processingStoreProportions", ->
				io.sockets.in(response.statusEmitter.hash).emit response.statusEmitter.hash, "processingStoreProportions"
				console.log "Hash: #{response.statusEmitter.hash}, Status: processingStoreProportions"
			response.statusEmitter.on "completed", ->
				io.sockets.in(response.statusEmitter.hash).emit response.statusEmitter.hash, "completed"
				console.log "Hash: #{response.statusEmitter.hash}, Status: completed"
		else
			res.jsonp response

web.get "/data/subcorpusStatus", (req, res, next) ->
	core.getSubcorpusStatus req.param("corpus"), req.param("subcorpus"), (err, result) ->
		return res.jsonp 500, err if err?
		res.jsonp result

web.get /\/([a-z]+)/, (req, res, next) ->
	res.render req.params[0], (err, html) ->
		next() if err
		res.send html

#web.get "*", (req, res) ->
#	res.render "404"

server = http.createServer web

io = socketIO.listen server
io.configure ->
	io.set "log level", 0

io.sockets.on "connection", (socket) ->
	socket.on "subscribe", (hash) ->
		console.log "Subscriber joined hash #{hash}"
		socket.join hash

server.listen (port = process.env.PORT ? 5080), -> console.log "Listening on port #{port}"
