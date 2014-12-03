# @cjsx React.DOM

browseTopics = require("../../../async-calls/browse-topics").calls
React = require "react"
RelatedArticles = require "./explore-topic/related-articles"
RelatedTopics = require "./explore-topic/related-topics"
TopPhrases = require "./explore-topic/top-phrases"
TopWords = require "./explore-topic/top-words"

module.exports = React.createClass
  displayName: "ExploreInferencer"
  propTypes:
    location: React.PropTypes.shape(
      ingestedCorpus: React.PropTypes.string.isRequired
      numTopics: React.PropTypes.number.isRequired
      entity: React.PropTypes.shape(
        _id: React.PropTypes.string.isRequired
        totalTokens: React.PropTypes.number.isRequired
        words: React.PropTypes.arrayOf React.PropTypes.shape(
          word: React.PropTypes.string.isRequired
          weight: React.PropTypes.number.isRequired
          count: React.PropTypes.number.isRequired
        ).isRequired
        phrases: React.PropTypes.arrayOf React.PropTypes.shape(
          phrase: React.PropTypes.string.isRequired
          weight: React.PropTypes.number.isRequired
          count: React.PropTypes.number.isRequired
        ).isRequired
      ).isRequired
    ).isRequired
    onLocationChange: React.PropTypes.func.isRequired

  getInitialState: ->
    articles: null
    loadingArticles: false

  handleLocationChanged: (location) ->
    @props.onLocationChange location

  render: ->
    <div className="row">
      <div className="col-sm-4">
        <TopWords location={@props.location} />
        <TopPhrases location={@props.location} />
      </div>
      <div className="col-sm-4">
        <RelatedArticles
          location={@props.location}
          onLocationChange={@handleLocationChanged}
        />
      </div>
      <div className="col-sm-4">
        <RelatedTopics
          location={@props.location}
          onLocationChange={@handleLocationChanged}
        />
      </div>
    </div>
