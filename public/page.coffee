require.config
	paths:
		jquery: "/components/jquery/jquery.min"
		bootstrap: "/components/bootstrap/dist/js/bootstrap.min"
		batman: "/batmanjs/batman"
		wordcloud: "/wordcloudjs/wordcloud"
	shim:
		bootstrap: deps: ["jquery"]
		batman: deps: ["jquery"], exports: "Batman"
		wordcloud: exports: "WordCloud"
	waitSeconds: 30

appContext = undefined

define "Batman", ["batman"], (Batman) -> Batman.DOM.readers.batmantarget = Batman.DOM.readers.target and delete Batman.DOM.readers.target and Batman

require ["jquery", "Batman", "wordcloud", "bootstrap"], ($, Batman, WordCloud) ->

	isScrolledIntoView = (elem) ->
		(elemTop = $(elem).position().top) >= 0 && (elemTop + $(elem).height()) <= $(elem).parent().height()

	class AppContext extends Batman.Model
		constructor: ->
			super
			@set "indexContext", new @IndexContext if window.location.pathname is "/"
			@set "topicsContext", new @TopicsContext if window.location.pathname is "/topics"

		class @::IndexContext extends Batman.Model
			constructor: ->
				super

		class @::TopicsContext extends Batman.Model
			@accessor "isCurrentTopicSelected", -> @get("currentTopic")?
			@accessor "filteredTopics", ->
				findInStr = (chars, str, j = 0) ->
					return [] if chars is ""
					return if (idx = str.indexOf chars[0]) is -1
					if (ret = findInStr chars[1..], str[(idx + 1)..], idx + j + 1)? then [idx + j].concat ret
				@get("topics")
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
			constructor: ->
				super
				@set "topicSearch_text", ""
				@set "topicsList_activeIndex", 0
				@set "topics", []
				$.ajax
					url: "/data/topicsList", dataType: "jsonp"
					success: (response) =>
						@set "topics", response.map (x) => new @Topic x
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
						@set "topicSearch_text", @get("topics")[@get "topicsList_activeIndex"]?.get("name") ? ""
						$("#topicSearch").blur()
						@get("topics")[@get "topicsList_activeIndex"]?.onReady (err, topic) =>
							wordsMax = Math.max topic.get("words").map((x) -> x.count)...
							wordsMin = Math.min topic.get("words").map((x) -> x.count)...
							phrasesMax = Math.max topic.get("phrases").map((x) -> x.count)...
							phrasesMin = Math.min topic.get("phrases").map((x) -> x.count)...
							@set "currentTopic", topic
							WordCloud $("#wordcloud")[0],
								list: topic.get("words").map (x) ->
									[x.word, (x.count - wordsMin + 1) / (wordsMax - wordsMin + 1) * 28 + 12]
								gridSize: 10
								minRotation: -0.5
								maxRotation: 0.5
								rotateRatio: 0.2
								abort: -> console.error arguments
							WordCloud $("#phrasecloud")[0],
								list: topic.get("phrases").map (x) ->
									[x.phrase, (x.count - phrasesMin + 1) / (phrasesMax - phrasesMin + 1) * 28 + 12]
								gridSize: 10
								minRotation: -0.5
								maxRotation: 0.5
								rotateRatio: 0.2
								abort: -> console.error arguments
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

			class @::Topic extends Batman.Model
				constructor: ({id, name}) ->
					super
					@set "id", id
					@set "name", name
				onReady: (callback) ->
					callback null, @ if @get "isLoaded"
					$.ajax
						url: "/data/topicDetails", dataType: "jsonp", data: id: @get "id"
						success: (response) =>
							@set "id", response.id
							@set "name", response.name
							@set "words", response.words
							@set "phrases", response.phrases
							@set "records", response.records
							callback null, @
						error: (request) ->
							console.error request
							callback request

	class STM extends Batman.App
		@appContext: appContext = new AppContext

	STM.run()
	$ ->
		appContext.set "pageLoaded", true