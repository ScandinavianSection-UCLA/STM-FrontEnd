# @cjsx React.DOM

Browse = require "./topics/browse"
Graph = require "./topics/graph"
React = require "react"
Tabs = require "./topics/tabs"

module.exports = React.createClass
  displayName: "Topics"
  getInitialState: ->
    activeTab: "browse"
    browseLocation:
      type: "topic"
    graphSeeds:
      topics: []
      articles: []
    graphNumNodesToExpandTo: 10

  handleTabChanged: (activeTab) ->
    @setState activeTab: activeTab

  handleBrowseLocationChanged: (location) ->
    @setState browseLocation: location

  handleGraphSeedsChanged: (graphSeeds) ->
    @setState graphSeeds: graphSeeds

  handleGraphNumNodesToExpandToChanged: (num) ->
    @setState graphNumNodesToExpandTo: num

  renderChild: ->
    switch @state.activeTab
      when "browse"
        <Browse
          location={@state.browseLocation}
          onLocationChange={@handleBrowseLocationChanged}
          graphSeeds={@state.graphSeeds}
          onGraphSeedsChange={@handleGraphSeedsChanged}
        />
      when "graph"
        <Graph
          graphSeeds={@state.graphSeeds}
          onGraphSeedsChange={@handleGraphSeedsChanged}
          onTabChange={@handleTabChanged}
          numNodesToExpandTo={@state.graphNumNodesToExpandTo}
          onNumNodesToExpandToChange={@handleGraphNumNodesToExpandToChanged}
        />

  render: ->
    <div className="container">
      <Tabs activeTab={@state.activeTab} onTabChange={@handleTabChanged} />
      {@renderChild()}
    </div>
