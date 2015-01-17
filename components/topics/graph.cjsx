# @cjsx React.DOM

GraphView = require "./graph/graph-view"
React = require "react"

module.exports = React.createClass
  displayName: "Graph"
  propTypes:
    graphSeeds: React.PropTypes.shape(
      topics: React.PropTypes.arrayOf React.PropTypes.string
      articles: React.PropTypes.arrayOf React.PropTypes.string
    ).isRequired
    onGraphSeedsChange: React.PropTypes.func.isRequired
    onTabChange: React.PropTypes.func.isRequired
    numNodesToExpandTo: React.PropTypes.number.isRequired
    onNumNodesToExpandToChange: React.PropTypes.func.isRequired

  getInitialState: ->
    containerWidth: @getContainerWidth()

  handleGoToBrowseClicked: ->
    @props.onTabChange "browse"

  handleNumNodesToExpandToChanged: (num) ->
    @props.onNumNodesToExpandToChange num

  render: ->
    if (
      @props.graphSeeds.topics.length is 0 and
      @props.graphSeeds.articles.length is 0
    )
      browseLink =
        <a href="#" onClick={@handleGoToBrowseClicked}>
          browse
        </a>
      <div className="text-muted text-center">
        Choose topics and articles to use as seed from {browseLink}.
      </div>
    else
      <GraphView
        graphSeeds={@props.graphSeeds}
        containerWidth={@state.containerWidth}
        numNodesToExpandTo={@props.numNodesToExpandTo}
        onNumNodesToExpandToChange={@handleNumNodesToExpandToChanged}
      />

  getContainerWidth: ->
    if window.innerWidth >= 1200
        1140
      else if window.innerWidth >= 992
        940
      else if window.innerWidth >= 768
        720
      else
        window.innerWidth - 30

  handleResize: ->
    containerWidth = @getContainerWidth()
    if @state.containerWidth isnt containerWidth
      @setState containerWidth: containerWidth

  componentDidMount: ->
    window.addEventListener "resize", @handleResize

  componentWillUnmount: ->
    window.removeEventListener "resize", @handleResize
