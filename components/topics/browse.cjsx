# @cjsx React.DOM

Breadcrumb = require "./browse/breadcrumb"
ExploreArticle = require "./browse/explore-article"
ExploreInferencer = require "./browse/explore-inferencer"
ExploreIngestedCorpus = require "./browse/explore-ingested-corpus"
ExploreTopic = require "./browse/explore-topic"
MakeSelection = require "./browse/make-selection"
React = require "react"

module.exports = React.createClass
  displayName: "Browse"
  propTypes:
    location: React.PropTypes.shape(
      type: React.PropTypes.string.isRequired
    ).isRequired
    onLocationChange: React.PropTypes.func.isRequired
    graphSeeds: React.PropTypes.shape(
      topics: React.PropTypes.arrayOf React.PropTypes.string
      articles: React.PropTypes.arrayOf React.PropTypes.string
    ).isRequired
    onGraphSeedsChange: React.PropTypes.func.isRequired

  handleLocationChanged: (location) ->
    @props.onLocationChange location

  handleGraphSeedsChanged: (graphSeeds) ->
    @props.onGraphSeedsChange graphSeeds

  renderChild: ->
    loc = @props.location
    if loc.type is "topic" and loc.ingestedCorpus? and loc.numTopics?
      if loc.entity?
        <ExploreTopic
          location={loc}
          onLocationChange={@handleLocationChanged}
        />
      else
        <ExploreInferencer
          location={loc}
          onLocationChange={@handleLocationChanged}
        />
    else if loc.type is "article" and loc.ingestedCorpus?
      if loc.entity?
        <ExploreArticle
          location={loc}
          onLocationChange={@handleLocationChanged}
        />
      else
        <ExploreIngestedCorpus
          location={loc}
          onLocationChange={@handleLocationChanged}
        />
    else
      <MakeSelection
        location={loc}
        onLocationChange={@handleLocationChanged}
      />

  render: ->
    <div>
      <Breadcrumb
        location={@props.location}
        onLocationChange={@handleLocationChanged}
        graphSeeds={@props.graphSeeds}
        onGraphSeedsChange={@handleGraphSeedsChanged}
      />
      {@renderChild()}
    </div>
