mongoose = require "mongoose"
async = require "async"
xml2js = require "xml2js"
fs = require "fs"
child_process = require "child_process"
crypto = require "crypto"
events = require "events"
colors = require "colors"

md5 = (str) ->
	crypto.createHash("md5").update(str).digest("hex")

fs.copyWithDuplicates = (sourceFile, targetFile, callback) ->
	rec = (i) ->
		fs.stat (tf = if i is 0 then targetFile else targetFile + " (#{i})"), (err, stat) ->
			if err?
				return fs.rename sourceFile, tf, (err) ->
					callback err, tf
			else
				rec i + 1
	rec 0

globalOptions =
	corpus: "english"
	subCorpus: "1888"
	corporaDir: "corpora"

mongoose.connect "/tmp/mongodb-27017.sock/stm_#{globalOptions.corpus}"

Topic = mongoose.model "Topic", new mongoose.Schema
	id: type: Number
	name: String
	hidden: Boolean

Record = mongoose.model "SubCorpus_#{globalOptions.subCorpus}", new mongoose.Schema
	article_id: String
	topic: type: mongoose.Schema.ObjectId, ref: "Topic"
	proportion: Number

metaDB = mongoose.createConnection "/tmp/mongodb-27017.sock/stm"

Corpus = metaDB.model "Corpus", (new mongoose.Schema
	name: String
	subcorpora: [
		name: String
		status: String
	]
), "corpora"

exports.getTopicsList = (callback) ->
	Topic.find({}).sort(name: 1).exec (err, topics) ->
		return callback err if err?
		callback null, topics.map (topic) ->
			name: topic.name
			id: topic.id
			hidden: topic.hidden ? false

exports.getTopicDetails = (id, callback) ->
	Topic.findOne id: id, (err, topic) ->
		return callback err if err?
		fs.readFile "/home/gotemb/topic1/1888topicphrasereport.xml", encoding: "utf8", (err, doc) ->
			return callback err if err?
			xml2js.parseString doc, (err, {topics: {topic: doc}}) ->
				return callback err if err?
				topicXML = doc.filter((x) -> x.$.id is "#{id}")[0]
				Record.find(topic: topic._id).sort(proportion: -1).limit(30).exec (err, records) ->
					return callback err if err?
					callback null,
						id: topic.id
						name: topic.name
						hidden: topic.hidden ? false
						words: topicXML.word.map (x) ->
							word: x._
							weight: Number x.$.weight
							count: Number x.$.count
						phrases: topicXML.phrase.map (x) ->
							phrase: x._
							weight: Number x.$.weight
							count: Number x.$.count
						records: records.map (x) ->
							article_id: x.article_id
							proportion: x.proportion

exports.getArticle = (article_id, callback) ->
	fs.readFile "/home/gotemb/topic1/1888_chunks/#{article_id}", encoding: "utf8", (err, doc) ->
		return callback err if err?
		callback null,
			article_id: article_id
			article: doc

exports.renameTopic = (id, newName, callback) ->
	Topic.findOneAndUpdate {id: id}, name: newName, (err, doc) ->
		return callback err if err?
		callback null, success: true

exports.setTopicHidden = (id, flag, callback) ->
	Topic.findOneAndUpdate {id: id}, hidden: flag, (err, doc) ->
		return callback err if err?
		callback null, success: true

exports.getCorporaList = (callback) ->
	#return callback null, ["English", "French", "Spanish", "German"]
	Corpus.find({}).sort(name: 1).exec (err, corpora) ->
		return callback err if err?
		callback null, corpora.map (x) -> x.name

exports.getSubcorporaList = (corpus, callback) ->
	#return callback null, corpus: corpus, subcorpora: [1..5].map (x) -> "#{corpus} #{x}"
	Corpus.findOne name: corpus, (err, corpus) ->
		return callback err if err?
		callback null, if corpus? then success: true, corpus: corpus, subcorpora: corpus.subcorpora.map((x) -> x.name) else success: false

exports.insertCorpus = (corpus, callback) ->
	Corpus.update {name: corpus}, {$setOnInsert: name: corpus, subcorpora: []}, upsert: true, (err, n, res) ->
		return callback err if err?
		callback null, success: !res.updatedExisting

exports.insertSubcorpus = (corpus, subcorpus, callback) ->
	Corpus.findOneAndUpdate {name: corpus, "subcorpora.name": $ne: subcorpus}, {$push: subcorpora: name: subcorpus}, (err, corpus) ->
		return callback err if err?
		callback null, success: corpus?

exports.addFile = (tempFile, corpus, subcorpus, callback) ->
	Corpus.findOne {name: corpus, "subcorpora.name": subcorpus}, {"subcorpora.$": 1}, (err, doc) ->
		return callback err if err?
		if doc?
			child_process.exec "file #{tempFile.path}", (err, stdout, stderr) ->
				console.error stderr.toString "utf8"
				return callback "#{err}: #{stderr.toString "utf8"}" if err?
				unless stdout.toString("utf8").toLowerCase().match(/(compress)|(zip)|(archive)|(tar)/)?
					fs.mkdir globalOptions.corporaDir, (err) ->
						fs.mkdir "#{globalOptions.corporaDir}/#{doc.subcorpora[0]._id.toString()}", (err) ->
							fs.mkdir "#{globalOptions.corporaDir}/#{doc.subcorpora[0]._id.toString()}/files", (err) ->
								fs.rename tempFile.path, "#{globalOptions.corporaDir}/#{doc.subcorpora[0]._id.toString()}/files/#{tempFile.name}", (err) ->
									unless err?
										callback null, success: true
									else
										callback null, success: false, error: err
				else
					fs.stat tempFile.path, (err, stat) ->
						return callback err if err?
						extractor = new events.EventEmitter
						extractor.archiveSize = stat.size
						extractor.bytesDone = 0
						extractor.status = "Extracting"
						extractor.hash = md5 "#{tempFile.path}#{Math.random()}#{doc.subcorpora[0]._id.toString()}"
						tempDir = "/tmp/#{extractor.hash}"
						fs.mkdir tempDir, (err) ->
							return callback err if err?
							callback null, status: "extracting", extractor: extractor
							tar_process = child_process.spawn "tar", ["-xzC", tempDir]
							fin = fs.createReadStream tempFile.path
							fin.on "data", (chunk) ->
								extractor.bytesDone += chunk.length
								extractor.emit "progress", bytesDone: extractor.bytesDone, percentDone: extractor.bytesDone / extractor.archiveSize * 100
								fin.pause() unless tar_process.stdin.write chunk
							fin.on "end", ->
								tar_process.stdin.end()
							tar_process.stdin.on "drain", -> fin.resume()
							tar_process.on "exit", (code, signal) ->
								extractor.status = "Completed with code #{code}"
								extractor.emit "extracted"
								fs.mkdir globalOptions.corporaDir, (err) ->
									fs.mkdir "#{globalOptions.corporaDir}/#{doc.subcorpora[0]._id.toString()}", (err) ->
										fs.mkdir "#{globalOptions.corporaDir}/#{doc.subcorpora[0]._id.toString()}/files", (err) ->
										processDir = (sourceDir, targetDir, callback) ->
											fs.readdir sourceDir, (err, files) ->
												async.map files, (file, callback) ->
													fs.stat "#{sourceDir}/#{file}", (err, stat) ->
														return callback err, [] if err?
														if stat.isDirectory()
															processDir "#{sourceDir}/#{file}", targetDir, callback
														else
															fs.copyWithDuplicates "#{sourceDir}/#{file}", "#{targetDir}/#{file}", (err, file) ->
																callback err, file.split("/")[-1..]
												, (err, files) ->
													callback null, files.reduce (a, b) -> a.concat b
										processDir tempDir, "#{globalOptions.corporaDir}/#{doc.subcorpora[0]._id.toString()}/files", (err, files) ->
											extractor.emit "completed"

		else
			fs.unlink tempFile.path, (err) ->
				callback null, success: false, error: "Corpora/Subcorpora does not exist."

exports.getFilesList = (corpus, subcorpus, from, callback) ->
	Corpus.findOne {name: corpus, "subcorpora.name": subcorpus}, {"subcorpora.$": 1}, (err, doc) ->
		return callback err if err?
		if doc?
			fs.readdir "#{globalOptions.corporaDir}/#{doc.subcorpora[0]._id.toString()}/files", (err, files) ->
				files = [] if err?
				callback null,
					corpus: corpus
					subcorpus: subcorpus
					totalFiles: files.length
					fileIndices: from: from, to: Math.min(from + 9, files.length - 1)
					files: files[from .. from + 9]
		else
			callback null, success: false, error: "Corpora/Subcorpora does not exist."

exports.processTopicModeling = (corpus, subcorpus, num_topics, callback) ->
	exports.processTopicModeling.statusEmitters ?= {}
	Corpus.findOneAndUpdate {name: corpus, "subcorpora.name": subcorpus, "subcorpora.status": $ne: "processing"}, {$set: "subcorpora.$.status": "processing"}, {"subcorpora.$": 1}, (err, doc) ->
		return callback err if err?
		if doc?
			ingestChunks = (callback) ->
				child_process.exec "mallet import-dir
					--input #{globalOptions.corporaDir}/#{doc.subcorpora[0]._id.toString()}/files/
					--output #{globalOptions.corporaDir}/#{doc.subcorpora[0]._id.toString()}/chunks.mallet
					--token-regex '\\p{L}[\\p{L}\\p{P}]*\\p{L}'
					--keep-sequence
					--remove-stopwords"
				, (err, stdout, stderr) ->
					console.log "--- IngestChunks ---"
					console.error stderr.toString "utf8"
					console.log stdout.toString "utf8"
					return callback "#{err}: #{stderr.toString "utf8"}" if err?
					callback()
			trainTopics = (callback) ->
				child_process.exec "mallet train-topics
					--input #{globalOptions.corporaDir}/#{doc.subcorpora[0]._id.toString()}/chunks.mallet
					--num-topics #{num_topics}
					--xml-topic-phrase-report #{globalOptions.corporaDir}/#{doc.subcorpora[0]._id.toString()}/topicreport.xml
					--inferencer-filename #{globalOptions.corporaDir}/#{doc.subcorpora[0]._id.toString()}/inferencer.mallet
					--random-seed 1
					--num-threads 2"
				, (err, stdout, stderr) ->
					console.log "--- TrainTopics ---"
					console.error stderr.toString("utf8").redBG
					console.log stdout.toString "utf8"
					return callback "#{err}: #{stderr.toString "utf8"}" if err?
					callback()
			inferTopics = (callback) ->
				child_process.exec "mallet infer-topics
					--inferencer #{globalOptions.corporaDir}/#{doc.subcorpora[0]._id.toString()}/inferencer.mallet
					--input #{globalOptions.corporaDir}/#{doc.subcorpora[0]._id.toString()}/chunks.mallet
					--output-doc-topics #{globalOptions.corporaDir}/#{doc.subcorpora[0]._id.toString()}/measuring.txt"
				, (err, stdout, stderr) ->
					console.log "--- InferTopics ---"
					console.error stderr.toString("utf8").redBG
					console.log stdout.toString "utf8"
					return callback "#{err}: #{stderr.toString "utf8"}" if err?
					callback()
			storeProportions = (callback) ->
				child_process.exec "coffee TopicSaturation-Importer/importer.coffee
					#{globalOptions.corporaDir}/#{doc.subcorpora[0]._id.toString()}/measuring.txt
					#{corpus}
					#{subcorpus}"
				, (err, stdout, stderr) ->
					console.log "--- StoreProportions ---"
					console.error stderr.toString("utf8").redBG
					console.log stdout.toString "utf8"
					return callback "#{err}: #{stderr.toString "utf8"}" if err?
					callback()
			emitter = new events.EventEmitter
			emitter.hash = md5 "processTopicModeling#{Math.random()}#{doc.subcorpora[0]._id.toString()}"
			exports.processTopicModeling.statusEmitters[doc.subcorpora[0]._id.toString()] = emitter
			callback null, success: true, statusEmitter: emitter
			emitter.status = "processingIngestChunks"
			ingestChunks (err) ->
				return console.error "Error in IngestChunks: #{err}".redBG if err?
				emitter.emit emitter.status = "processingTrainTopics"
				trainTopics (err) ->
					return console.error "Error in TrainTopics: #{err}".redBG if err?
					emitter.emit emitter.status = "processingInferTopics"
					inferTopics (err) ->
						return console.error "Error in InferTopics: #{err}".redBG if err?
						emitter.emit emitter.status = "processingStoreProportions"
						storeProportions (err) ->
							# return console.error "Error in StoreProportions: #{err}".redBG if err?
							emitter.emit emitter.status = "completed"
							Corpus.findOneAndUpdate {name: corpus, "subcorpora.name": subcorpus, "subcorpora.status": "processing"}, {$set: "subcorpora.$.status": "processed"}, {"subcorpora.$": 1}, ->
								delete exports.processTopicModeling.statusEmitters[doc.subcorpora[0]._id.toString()]
		else
			callback null, success: false, error: "Corpora/Subcorpora does not exist or is already being processed."

exports.getSubcorpusStatus = (corpus, subcorpus, callback) ->
	Corpus.findOne {name: corpus, "subcorpora.name": subcorpus}, {"subcorpora.$": 1}, (err, doc) ->
		return callback err if err?
		if doc?
			unless doc.subcorpora[0].status
				callback null, success: true, status: "not processed"
			else if doc.subcorpora[0].status is "processing"
				callback null, success: true, status: exports.processTopicModeling.statusEmitters[doc.subcorpora[0]._id.toString()].status, hash: exports.processTopicModeling.statusEmitters[doc.subcorpora[0]._id.toString()]
			else if doc.subcorpora[0].status is "processed"
				callback null, success: true, status: "completed"
		else
			callback null, success: false, error: "Corpora/Subcorpora does not exist."

# Deprecated
exports.getTopics = (callback) ->
	fs.readFile "/home/gotemb/topic1/1888topicphrasereport.xml", encoding: "utf8", (err, doc) ->
		xml2js.parseString doc, (err, {topics: {topic: doc}}) ->
			Topic.find {}, (err, topics) ->
				async.map topics, (topic, callback) ->
					Record.find(topic: topic._id).sort(proportion: -1).limit(30).exec (err, records) ->
						callback err,
							topic: topic.toJSON()
							records: records.map (x) -> x.toJSON()
							words:
								doc.filter((x) -> topic.id is Number x.$.id)[0].word.map (x) ->
									word: x._
									weight: Number x.$.weight
									count: Number x.$.count
							phrases:
								doc.filter((x) -> topic.id is Number x.$.id)[0].phrase.map (x) ->
									phrase: x._
									weight: Number x.$.weight
									count: Number x.$.count
				, callback