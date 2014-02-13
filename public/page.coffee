require.config
	paths:
		jquery: "/components/jquery/jquery.min"
		bootstrap: "/components/bootstrap/dist/js/bootstrap.min"
		batman: "/batmanjs/batman.min"
		wordcloud: "/wordcloudjs/wordcloud.min"
	shim:
		bootstrap: deps: ["jquery"]
		batman: deps: ["jquery"], exports: "Batman"
		wordcloud: exports: "WordCloud"
	waitSeconds: 30

appContext = undefined

define "Batman", ["batman"], (Batman) -> Batman.DOM.readers.batmantarget = Batman.DOM.readers.target and delete Batman.DOM.readers.target and Batman

require ["jquery", "Batman", "bootstrap"], ($, Batman) ->

	class AppContext extends Batman.Model
		constructor: ->
			super
			@set "IndexContext", new @IndexContext if window.location.pathname is "/"

		class @::IndexContext extends Batman.Model
			constructor: ->
				super

	class STM extends Batman.App
		@appContext: appContext = new AppContext

	STM.run()
	$ ->
		WordCloud()
		appContext.set "pageLoaded", true