# @cjsx React.DOM

ArticleContent = require "./explore-article/article-content"
React = require "react"
RelatedArticles = require "./explore-article/related-articles"
RelatedInferencers = require "./explore-article/related-inferencers"

module.exports = React.createClass
  displayName: "ExploreArticle"
  propTypes:
    location: React.PropTypes.shape(
      ingestedCorpus: React.PropTypes.string.isRequired
      entity: React.PropTypes.shape(
        _id: React.PropTypes.string.isRequired
        name: React.PropTypes.string.isRequired
      ).isRequired
    ).isRequired
    onLocationChange: React.PropTypes.func.isRequired

  getInitialState: ->
    highlightedTopic: null

  handleLocationChanged: (location) ->
    @props.onLocationChange location

  handleHighlightedTopicChanged: (topic) ->
    @setState highlightedTopic: topic

  render: ->
    <div className="row">
      <div className="col-sm-4">
        <RelatedInferencers
          location={@props.location}
          onLocationChange={@handleLocationChanged}
          onHighlightedTopicChange={@handleHighlightedTopicChanged}
        />
        <RelatedArticles
          location={@props.location}
          onLocationChange={@handleLocationChanged}
        />
      </div>
      <div className="col-sm-8">
        <ArticleContent
          location={@props.location}
          highlightedTopic={@state.highlightedTopic}
        />
      </div>
    </div>
