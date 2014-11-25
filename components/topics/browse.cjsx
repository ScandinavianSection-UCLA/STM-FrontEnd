# @cjsx React.DOM

Breadcrumb = require "./browse/breadcrumb"
ExploreInferencer = require "./topics/explore-inferencer"
ExploreIngestedCorpus = require "./topics/explore-ingested-corpus"
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
      <ExploreInferencer />
    else if loc.type is "article" and loc.ingestedCorpus?
      <ExploreIngestedCorpus />
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
