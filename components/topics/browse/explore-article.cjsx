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
      entity: React.PropTypes.string.isRequired
    ).isRequired
    onLocationChange: React.PropTypes.func.isRequired

  handleLocationChanged: (location) ->
    @props.onLocationChange location

  render: ->
    <div className="row">
      <div className="col-sm-4">
        <RelatedInferencers
          location={@props.location}
          onLocationChange={@handleLocationChanged}
        />
        <RelatedArticles
          location={@props.location}
          onLocationChange={@handleLocationChanged}
        />
      </div>
      <div className="col-sm-8">
        <ArticleContent location={@props.location} />
      </div>
    </div>
