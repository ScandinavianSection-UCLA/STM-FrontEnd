require.config
	paths:
		jquery: "/components/jquery/dist/jquery.min"
		bootstrap: "/components/bootstrap/dist/js/bootstrap.min"
		batman: "/batmanjs/batman"
		wordcloud: "/wordcloudjs/wordcloud"
		typeahead: "/components/typeahead.js/dist/typeahead.bundle.min"
		dropzone: "/components/dropzone/downloads/dropzone-amd-module.min"
		socketIO: "/socket.io/socket.io"
		async: "/components/async/lib/async"
	shim:
		bootstrap: deps: ["jquery"]
		batman: deps: ["jquery"], exports: "Batman"
		wordcloud: exports: "WordCloud"
		typeahead: deps: ["jquery"]
		dropzone: deps: ["jquery"]
	waitSeconds: 30

appContext = undefined

define "Batman", ["batman"], (Batman) -> Batman.DOM.readers.batmantarget = Batman.DOM.readers.target and delete Batman.DOM.readers.target and Batman

require ["jquery", "Batman", "wordcloud", "socketIO", "async", "bootstrap", "typeahead", "dropzone"], ($, Batman, WordCloud, socketIO, async) ->

	findInStr = (chars, str, j = 0) ->
		return [] if chars is ""
		return if (idx = str.indexOf chars[0]) is -1
		if (ret = findInStr chars[1..], str[(idx + 1)..], idx + j + 1)? then [idx + j].concat ret

	isScrolledIntoView = (elem) ->
		(elemTop = $(elem).position().top) >= 0 && (elemTop + $(elem).height()) <= $(elem).parent().height()

	class AppContext extends Batman.Model
		constructor: ->
			super
			@set "indexContext", Index.context = new Index.Context if window.location.pathname is "/"
			@set "topicsContext", Topics.context = new Topics.Context if window.location.pathname is "/topics"
			@set "curationContext", Curation.context = new Curation.Context if window.location.pathname is "/curation"

	Index = new Object
	do (exports = Index) ->
		class exports.Context extends Batman.Model
			constructor: ->
				super

	Topics = new Object
	do (exports = Topics) ->
		class exports.Context extends Batman.Model
			@accessor "isCurrentTopicSelected", -> @get("currentTopic")?
			@accessor "filteredTopics", ->
				@get("topics")
					.sort (a, b) -> a.get("name").localeCompare b.get("name")
					.sort (a, b) -> (if a.get("hidden") then 1 else 0) - (if b.get("hidden") then 1 else 0)
					.map (topic) =>
						topic: topic
						indices: findInStr @get("topicSearch_text").toLowerCase(), topic.get("name").toLowerCase()
					.filter (x) -> x.indices?
					.map (topic, idx) =>
						topic: topic.topic
						indices: topic.indices
						active: idx is @get("topicsList_activeIndex")
						html: (for c, i in topic.topic.get("name")
							if i in topic.indices then "<strong>#{c}</strong>" else c
						).join ""
			@accessor "filteredTopics_unhidden", -> @get("filteredTopics").filter (x) -> !x.topic.get("hidden")
			@accessor "filteredTopics_hidden", -> @get("filteredTopics").filter (x) -> x.topic.get("hidden")
			@accessor "anyFilteredTopics_hidden", -> @get("filteredTopics_hidden").length > 0
			constructor: ->
				super
				@set "topicSearch_text", ""
				@set "topicsList_activeIndex", 0
				@set "topics", []
				$.ajax
					url: "/data/topicsList", dataType: "jsonp"
					success: (response) =>
						@set "topics", response.map (x) => new Topic x
					error: (request) ->
						console.error request
				$("#topicSearch")
					.popover
						html: true, animation: false, placement: "bottom", trigger: "focus", content: -> $("#topicsList")
					.on "hide.bs.popover", -> $("#hidden-content").append $("#topicsList")
			topicSearch_keydown: (node, e) ->
				e.preventDefault() if e.which in [13, 27, 38, 40]
				switch e.which
					when 13
						$("#topicSearch").blur()
						@get("filteredTopics")[@get "topicsList_activeIndex"]?.topic?.onReady (err, topic) =>
							@set "currentTopic", topic
							@drawWordCloud()
							@drawPhraseCloud()
						@set "topicSearch_text", @get("filteredTopics")[@get "topicsList_activeIndex"]?.topic?.get("name") ? ""
						@set "topicsList_activeIndex", 0
					when 27
						$("#topicSearch").blur()
					when 38
						@set "topicsList_activeIndex", ((fl = @get("filteredTopics").length) + @get("topicsList_activeIndex") - 1) % fl
						$("#topicsList a.list-group-item.active")[0].scrollIntoView true unless isScrolledIntoView "#topicsList a.list-group-item.active"
					when 40
						@set "topicsList_activeIndex", (@get("topicsList_activeIndex") + 1) % @get("filteredTopics").length
						$("#topicsList a.list-group-item.active")[0].scrollIntoView false unless isScrolledIntoView "#topicsList a.list-group-item.active"
			topicSearch_input: ->
				@set "topicsList_activeIndex", 0
			drawWordCloud: ->
				wordsMax = Math.max @get("currentTopic").get("words").map((x) -> x.count)...
				wordsMin = Math.min @get("currentTopic").get("words").map((x) -> x.count)...
				WordCloud $("#wordcloud")[0],
					list: @get("currentTopic").get("words").map (x) ->
						[x.word, (x.count - wordsMin + 1) / (wordsMax - wordsMin + 1) * 30 + 12]
					gridSize: 10
					minRotation: -0.5
					maxRotation: 0.5
					rotateRatio: 0.2
					ellipticity: 0.5
					wait: 0
					abort: -> console.error arguments
			drawPhraseCloud: ->
				phrasesMax = Math.max @get("currentTopic").get("phrases").map((x) -> x.count)...
				phrasesMin = Math.min @get("currentTopic").get("phrases").map((x) -> x.count)...
				WordCloud $("#phrasecloud")[0],
					list: @get("currentTopic").get("phrases").map (x) ->
						[x.phrase, (x.count - phrasesMin + 1) / (phrasesMax - phrasesMin + 1) * 30 + 12]
					gridSize: 10
					minRotation: -0.5
					maxRotation: 0.5
					rotateRatio: 0.2
					ellipticity: 0.5
					wait: 0
					abort: -> console.error arguments
			gotoTopic: (node) ->
				@get("topics").filter((x) -> x.get("id") is Number $(node).data "id")[0]?.onReady (err, topic) =>
					@set "currentTopic", topic
					@drawWordCloud()
					@drawPhraseCloud()
				@set "topicSearch_text", @get("topics").filter((x) -> x.get("id") is Number $(node).data "id")[0]?.get("name") ? ""
				@set "topicsList_activeIndex", 0

		class Topic extends Batman.Model
			@accessor "filteredRecords", ->
				@get("records")?.map (record, idx) =>
					record: record
					active: record is @get "activeRecord"
			@accessor "toggleHidden_text", -> "#{if @get("hidden") then "Unhide" else "Hide"} Topic"
			constructor: ({id, name, hidden}) ->
				super
				@set "id", id
				@set "name", name
				@set "hidden", hidden
				@set "isLoaded", false
			onReady: (callback) ->
				return callback null, @ if @get "isLoaded"
				$.ajax
					url: "/data/topicDetails", dataType: "jsonp", data: id: @get "id"
					success: (response) =>
						@set "id", response.id
						@set "name", response.name
						@set "words", response.words
						@set "phrases", response.phrases
						@set "records", response.records.map (x) => new Record x
						@set "isLoaded", true
						callback null, @
					error: (request) ->
						console.error request
						callback request
			gotoRecord: (node) ->
				@get("records").filter((x) -> x.get("article_id") is $(node).children("span").text())[0]?.onReady (err, record) =>
					@set "activeRecord", record
			showRenameDialog: ->
				@set "renameTopic_text", @get "name"
				$("#renameTopicModal").modal "show"
			renameTopic: ->
				$.ajax
					url: "/data/renameTopic", dataType: "jsonp", type: "POST", data: id: @get("id"), name: @get("renameTopic_text")
					success: (response) =>
						@set "name", @get "renameTopic_text"
						appContext.set "topicsContext.topicSearch_text", @get "name" if appContext.get("topicsContext.currentTopic") is @
						$("#renameTopicModal").modal "hide"
					error: (request) ->
						console.error request
			toggleHidden: ->
				$.ajax
					url: "/data/setTopicHidden", dataType: "jsonp", type: "POST", data: id: @get("id"), hidden: !@get("hidden")
					success: (response) =>
						@set "hidden", !@get "hidden"
					error: (request) ->
						console.error request

		class Record extends Batman.Model
			@accessor "proportionPie", ->
				p = 100 * @get "proportion"
				p = 99.99 if p > 99.99
				"""
					M 18 18
					L 33 18
					A 15 15 0 #{if p < 50 then 0 else 1} 0 #{18 + 15 * Math.cos p * Math.PI / 50} #{18 - 15 * Math.sin p * Math.PI / 50}
					Z
				"""
			@accessor "proportionTooltip", -> "Proportion: #{(@get("proportion") * 100).toFixed 2}%"
			constructor: ({article_id, proportion}) ->
				super
				@set "article_id", article_id
				@set "proportion", proportion
				@set "isLoaded", false
			onReady: (callback) ->
				return callback null, @ if @get "isLoaded"
				$.ajax
					url: "/data/article", dataType: "jsonp", data: article_id: @get "article_id"
					success: (response) =>
						@set "article_id", response.article_id
						@set "article", response.article
						@set "isLoaded", true
						callback null, @
					error: (request) ->
						console.error request
						callback request

	Curation = new Object
	do (exports = Curation) ->
		socket = undefined

		class exports.Context extends Batman.Model
			constructor: ->
				super
				@set "metadataView", new MetadataView
				@set "addFilesView", new AddFilesView
				@set "pendingTasksView", new PendingTasksView
				@set "malletProcessView", new MalletProcessView
				socket = socketIO.connect()

		class MetadataView extends Batman.Model
			@accessor "currentCorpus", -> @get("corpora").find((x) => x.get("name") is @get "corpus_text")
			@accessor "currentSubcorpus", -> @get("currentCorpus.subcorpora")?.find((x) => x.get("name") is @get "subcorpus_text")
			@accessor "corpusIsNew", -> !@get("currentCorpus")? and !@get("corpus_text").match(/^\s*$/)? and !@get("corpus_typeahead_open")
			@accessor "corpusIsSelected", -> @get("currentCorpus")?
			@accessor "subcorpusIsNew", -> !@get("currentSubcorpus")? and !@get("subcorpus_text").match(/^\s*$/)? and !@get("subcorpus_typeahead_open") and @get("currentCorpus")?
			@accessor "subcorpusIsSelected", -> @get("currentSubcorpus")?
			constructor: ->
				super
				@set "corpora", new Batman.Set
				@set "corpus_text", ""
				@set "subcorpus_text", ""
				@set "corpus_typeahead_open", false
				@set "subcorpus_typeahead_open", false
				@observe "currentCorpus", (corpus) ->
					corpus?.loadSubcorpora()
				@observe "currentSubcorpus", (subcorpus) ->
					subcorpus?.loadFilesList 0, ->
						subcorpus?.get("filesList").add()
					exports.context.get("malletProcessView").loadStatus() if subcorpus?
				$.ajax
					url: "/data/corporaList", dataType: "jsonp"
					success: (response) =>
						@get("corpora").add (response.map (x) => new Corpus x)...
					error: (request) ->
						console.error request
				$ "#corpusInput"
					.typeahead {minLength: 0, highlight: true},
						source: (query, callback) =>
							callback @get("corpora").filter((x) -> x.get("name").toLowerCase().match query.toLowerCase()).toArray()
						displayKey: (x) -> x.get "name"
					.on "typeahead:opened", => @set "corpus_typeahead_open", true
					.on "typeahead:closed", => @set "corpus_typeahead_open", false
					.on "typeahead:selected", => @set "corpus_text", $("#corpusInput").typeahead("val")
				$ "#subcorpusInput"
					.typeahead {minLength: 0, highlight: true},
						source: (query, callback) =>
							@get("currentCorpus")?.loadSubcorpora (err, corpus) =>
								callback corpus.get("subcorpora").filter((x) -> x.get("name").toLowerCase().match query.toLowerCase()).toArray()
						displayKey: (x) -> x.get "name"
					.on "typeahead:opened", => @set "subcorpus_typeahead_open", true
					.on "typeahead:closed", => @set "subcorpus_typeahead_open", false
					.on "typeahead:selected", => @set "subcorpus_text", $("#subcorpusInput").typeahead("val")
			addCorpus: ->
				$.ajax
					url: "/data/corpus", dataType: "jsonp", type: "PUT", data: corpus: @get("corpus_text")
					success: ({success}) =>
						return console.error "Corpus already exists." unless success
						@get("corpora").add new Corpus @get "corpus_text"
					error: (request) ->
						console.error request
			addSubcorpus: ->
				corpus = @get("currentCorpus")
				return unless corpus?
				$.ajax
					url: "/data/subcorpus", dataType: "jsonp", type: "PUT", data: corpus: corpus.get("name"), subcorpus: @get("subcorpus_text")
					success: ({success}) =>
						return console.error "Subcorpus already exists or Corpus doesn't exist." unless success
						corpus.loadSubcorpora (err, corpus) =>
							corpus.get("subcorpora").add new Subcorpus @get("subcorpus_text"), corpus
					error: (request) ->
						console.error request

		class AddFilesView extends Batman.Model
			@accessor "isFilesListEmpty", -> !exports.context.get("metadataView.currentSubcorpus")? or exports.context.get("metadataView.currentSubcorpus.filesList.length") is 0
			@accessor "sortedFilesList", -> exports.context.get "metadataView.currentSubcorpus.sortedFilesList"
			@accessor "filesListNextAvailable", -> exports.context.get "metadataView.currentSubcorpus.filesListNextAvailable"
			@accessor "filesListPrevAvailable", -> exports.context.get "metadataView.currentSubcorpus.filesListPrevAvailable"
			constructor: ->
				$("#dropFiles").dropzone
					url: "/data/file"
					parallelUploads: 5
					accept: (file, callback) ->
						callback if exports.context.get("metadataView.currentSubcorpus")? then undefined else "Error: Corpus / Subcorpus not selected."
					sending: (file, xhr, formData) ->
						file.task = new UploadTask file.name, file.size, (currentCorpus = exports.context.get "metadataView.currentCorpus"), (currentSubcorpus = exports.context.get "metadataView.currentSubcorpus")
						exports.context.get("pendingTasksView.pendingTasks").add file.task
						formData.append "corpus", currentCorpus.get "name"
						formData.append "subcorpus", currentSubcorpus.get "name"
					uploadprogress: (file, percentDone, bytesSent) ->
						file.task.set "bytesSent", bytesSent
					success: (file, res) ->
						if res.success
							file.task.set "status", "success"
						else if res.status is "extracting"
							file.task.set "status", "extracting"
							socket.emit "subscribe", res.hash
							socket.on res.hash, (message, result) ->
								switch message
									when "progress"
										file.task.set "bytesExtracted", result.bytesDone
									when "extracted"
										file.task.set "status", "extracted"
									when "completed"
										file.task.set "status", "success"
										from = exports.context.get "metadataView.currentSubcorpus.filesListLoadedFrom"
										to = exports.context.get "metadataView.currentSubcorpus.filesListLoadedTo"
										async.eachSeries ((x for x in [from ... to - 10] by 10).concat Math.max to - 10, 0), (x, callback) ->
											exports.context.get("metadataView.currentSubcorpus").forceLoadFilesList x
						else
							file.task.set "status", "failure"
						console.error res.error if res.error?
					error: (file, error) ->
						file.task?.set "status", "failure"
					previewsContainer: document.createElement("div")
			loadMoreNextFiles: ->
				exports.context.get("metadataView.currentSubcorpus").loadFilesList (exports.context.get("metadataView.currentSubcorpus.filesListLoadedTo") ? 0) + 1
			loadMorePrevFiles: ->
				exports.context.get("metadataView.currentSubcorpus").loadFilesList Math.max ((exports.context.get("metadataView.currentSubcorpus.filesListLoadedFrom") ? 0) - 10), 0

		class PendingTasksView extends Batman.Model
			@accessor "isEmpty", -> @get("pendingTasks.length") is 0
			constructor: ->
				super
				@set "pendingTasks", new Batman.Set

		class MalletProcessView extends Batman.Model
			@accessor "processing", -> @get("status")?
			@accessor "processingIngestChunks", -> @get("status") is "processingIngestChunks"
			@accessor "processingTrainTopics", -> @get("status") is "processingTrainTopics"
			@accessor "processingInferTopics", -> @get("status") is "processingInferTopics"
			@accessor "processingStoreProportions", -> @get("status") is "processingStoreProportions"
			@accessor "processedIngestChunks", -> @get("status") in ["processingTrainTopics", "processingInferTopics", "processingStoreProportions", "completed"]
			@accessor "processedTrainTopics", -> @get("status") in ["processingInferTopics", "processingStoreProportions", "completed"]
			@accessor "processedInferTopics", -> @get("status") in ["processingStoreProportions", "completed"]
			@accessor "processedStoreProportions", -> @get("status") in ["completed"]
			@accessor "notprocessedIngestChunks", -> not @get("processingIngestChunks") and not @get("processedIngestChunks")
			@accessor "notprocessedTrainTopics", -> not @get("processingTrainTopics") and not @get("processedTrainTopics")
			@accessor "notprocessedInferTopics", -> not @get("processingInferTopics") and not @get("processedInferTopics")
			@accessor "notprocessedStoreProportions", -> not @get("processingStoreProportions") and not @get("processedStoreProportions")
			loadStatus: ->
				@set "loaded", false
				corpus = exports.context.get "metadataView.currentCorpus"
				subcorpus = exports.context.get "metadataView.currentSubcorpus"
				$.ajax
					url: "/data/subcorpusStatus", dataType: "jsonp", type: "GET", data: corpus: corpus.get("name"), subcorpus: subcorpus.get("name")
					success: ({success, status, hash, error}) =>
						return console.error error unless success
						if status isnt "not processed"
							@set "status", status
							@subscribeToProcessEvents()
						@set "loaded", true
					error: (request) ->
						console.error request
						@set "loaded", true
			startTopicModeling: ->
				corpus = exports.context.get "metadataView.currentCorpus"
				subcorpus = exports.context.get "metadataView.currentSubcorpus"
				$.ajax
					url: "/data/startTopicModeling", dataType: "jsonp", type: "POST", data: corpus: corpus.get("name"), subcorpus: subcorpus.get("name"), num_topics: 50
					success: ({success, hash, error}) =>
						return console.error error unless success
						@set "status", "processingIngestChunks"
						console.log "processingIngestChunks"
						@subscribeToProcessEvents()
					error: (request) ->
						console.error request
			subscribeToProcessEvents: ->
				socket.emit "subscribe", hash
				socket.on hash, (message) =>
					switch message
						when "processingTrainTopics"
							@set "status", "processingTrainTopics"
							console.log "processingTrainTopics"
						when "processingInferTopics"
							@set "status", "processingInferTopics"
							console.log "processingInferTopics"
						when "processingStoreProportions"
							@set "status", "processingStoreProportions"
							console.log "processingStoreProportions"
						when "completed"
							@set "status", "completed"
							console.log "completed"

		class Corpus extends Batman.Model
			constructor: (name) ->
				super
				@set "name", name
				@set "subcorpora", new Batman.Set
			loadSubcorpora: (callback) ->
				return callback? null, @ if @get "isSubcorporaLoaded"
				$.ajax
					url: "/data/subcorporaList", dataType: "jsonp", data: corpus: @get "name"
					success: (response) =>
						@get("subcorpora").add (response.subcorpora.map (x) => new Subcorpus x, @)...
						@set "isSubcorporaLoaded", true
						callback? null, @
					error: (request) ->
						console.error request
						callback? request

		class Subcorpus extends Batman.Model
			@accessor "isFilesListEmpty", -> @get("filesList.length") is 0
			@accessor "sortedFilesList", -> @get("filesList.toArray").sort (a, b) -> a.localeCompare b
			constructor: (name, corpus) ->
				super
				@set "name", name
				@set "corpus", corpus
				@set "filesList", new Batman.Set
			loadFilesList: (from, callback) ->
				return callback? null, @ unless false in (x in [@get("filesListLoadedFrom") .. @get("filesListLoadedTo")] for x in [from, from + 9])
				@forceLoadFilesList from, callback
			forceLoadFilesList: (from, callback) ->
				$.ajax
					url: "/data/filesList", dataType: "jsonp", data: corpus: @get("corpus.name"), subcorpus: @get("name"), from: from
					success: (response) =>
						@get("filesList").add response.files...
						if response.fileIndices.from >= @get("filesListLoadedFrom") and response.fileIndices.to <= @get("filesListLoadedTo")
						else unless response.fileIndices.from > @get "filesListLoadedFrom"
							@set "filesListLoadedFrom", response.fileIndices.from
							@set "filesListLoadedTo", Math.max(response.fileIndices.to, Math.min(response.fileIndices.from + 29, @get("filesListLoadedTo") ? 0))
							@get("filesList").remove (@get("filesList.toArray").sort((a, b) -> a.localeCompare b)[30...])...
						else unless response.fileIndices.to < @get "filesListLoadedTo"
							@set "filesListLoadedTo", response.fileIndices.to
							@set "filesListLoadedFrom", Math.min(response.fileIndices.from, Math.max(response.fileIndices.to - 29, @get("filesListLoadedFrom") ? 0))
							@get("filesList").remove (@get("filesList.toArray").sort((a, b) -> a.localeCompare b)[...-30])...
						callback? null, @
						@set "filesListNextAvailable", @get("filesListLoadedTo") + 1 < response.totalFiles
						@set "filesListPrevAvailable", @get("filesListLoadedFrom") > 0
					error: (request) ->
						console.error request
						callback? request

		class UploadTask extends Batman.Model
			@accessor "friendlyFileSize", ->
				suffixes = ["KiB", "MiB", "GiB", "TiB"]
				order = Math.min (parseInt Math.log(@get("fileSize") + 1) / Math.log 1024), 4
				if order is 0
					"#{@get "fileSize"} bytes"
				else
					"#{(@get("fileSize") / Math.pow(1024, order)).toFixed 2} #{suffixes[order - 1]}"
			@accessor "percentDone", -> @get("bytesSent")/@get("fileSize") * 100
			@accessor "percentExtractionDone", -> @get("bytesExtracted")/@get("fileSize") * 100
			@accessor "success", -> @get("status") is "success"
			@accessor "failure", -> @get("status") is "failure"
			@accessor "extracting", -> @get("status") is "extracting"
			@accessor "extracted", -> @get("status") is "extracted"
			@accessor "isArchive", -> @get("status") in ["extracted", "extracting"]
			constructor: (fileName, fileSize, corpus, subcorpus) ->
				super
				@set "fileName", fileName
				@set "corpus", corpus
				@set "subcorpus", subcorpus
				@set "fileSize", fileSize
				@set "bytesSent", 0
				@observe "status", (success, extracted) ->
					exports.context.get("metadataView.currentSubcorpus.filesList").add fileName if success is "success" and extracted isnt "extracted"

	class STM extends Batman.App
		@appContext: appContext = new AppContext

	STM.run()
	$ ->
		appContext.set "pageLoaded", true
		setInterval (-> $("#relatedArticles svg:not([data-ttd='true'])").tooltip().attr "data-ttd", true), 1000
