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
  getInitialState: ->
    location:
      type: "topic"

  handleLocationChanged: (location) ->
    @setState location: location

  renderChild: ->
    loc = @state.location
    if loc.type is "topic" and loc.ingestedCorpus? and loc.numTopics?
      if loc.entity?
        <ExploreTopic
          location={@state.location}
          onLocationChange={@handleLocationChanged}
        />
      else
        <ExploreInferencer
          location={@state.location}
          onLocationChange={@handleLocationChanged}
        />
    else if loc.type is "article" and loc.ingestedCorpus?
      if loc.entity?
        <ExploreArticle
          location={@state.location}
          onLocationChange={@handleLocationChanged}
        />
      else
        <ExploreIngestedCorpus
          location={@state.location}
          onLocationChange={@handleLocationChanged}
        />
    else
      <MakeSelection
        location={@state.location}
        onLocationChange={@handleLocationChanged}
      />

  render: ->
    <div>
      <Breadcrumb
        location={@state.location}
        onLocationChange={@handleLocationChanged}
      />
      {@renderChild()}
    </div>
