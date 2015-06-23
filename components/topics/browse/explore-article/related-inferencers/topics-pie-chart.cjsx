# @cjsx React.DOM

d3 = require "d3"
deepEqual = require "deep-equal"
React = require "react"

module.exports = React.createClass
  displayName: "PieChart"
  propTypes:
    inferencer: React.PropTypes.shape(
      ingestedCorpus: React.PropTypes.string.isRequired
      numTopics: React.PropTypes.number.isRequired
      topics: React.PropTypes.arrayOf(
        React.PropTypes.shape(
          topic: React.PropTypes.shape(
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
          proportion: React.PropTypes.number.isRequired
        ).isRequired
      ).isRequired
    )
    width: React.PropTypes.number.isRequired
    height: React.PropTypes.number.isRequired
    radius: React.PropTypes.number.isRequired
    onLocationChange: React.PropTypes.func.isRequired
    onHighlightedTopicChange: React.PropTypes.func.isRequired

  getInitialState: ->
    @getDefaultState()

  getDefaultState: ->
    activeTopic: @props.inferencer.topics[0]

  componentWillReceiveProps: (props) ->
    unless deepEqual @props.inferencer, props.inferencer
      @setState @getDefaultState()

  handleTopicMouseEnter: (topic) ->
    @setState activeTopic: topic
    @props.onHighlightedTopicChange topic.topic

  handleTopicMouseLeave: ->
    @props.onHighlightedTopicChange null

  handleTopicClicked: (topic) ->
    @props.onLocationChange
      type: "topic"
      ingestedCorpus: @props.inferencer.ingestedCorpus
      numTopics: @props.inferencer.numTopics
      entity: topic.topic

  renderArc: (arc, d, i) ->
    pathStyle =
      fill:
        if @state.activeTopic is d.data then "#adc9e2"
        else "#5b94c5"
      cursor: "pointer"
    centroid = arc.centroid d
    distToCentroid = Math.sqrt(
      centroid
        .map (x) -> x * x
        .reduce (c, x) -> c + x
      )
    translateArc = centroid.map (x) -> x / distToCentroid * 10
    transform = "translate(#{translateArc})"
    <path
      d={arc d}
      style={pathStyle}
      key={i}
      onMouseEnter={@handleTopicMouseEnter.bind @, d.data}
      onMouseLeave={@handleTopicMouseLeave.bind @, d.data}
      onClick={@handleTopicClicked.bind @, d.data}
      transform={transform}
    />

  renderSVG: ->
    pie = d3.layout.pie()
      .value (x) -> x.proportion
      .startAngle Math.PI * 0.5
      .endAngle Math.PI * 2.5
    arc = d3.svg.arc()
      .outerRadius @props.radius - 10
      .innerRadius 0
    svgStyle =
      margin: "5px 0"
    <svg width={@props.width} height={@props.height} style={svgStyle}>
      <g transform="translate(#{@props.width / 2}, #{@props.height / 2})">
        {@renderArc arc, d, i for d, i in pie @props.inferencer.topics}
      </g>
    </svg>

  render: ->
    sumValues = @props.inferencer.topics
      .reduce ((sum, x) -> sum + x.proportion), 0
    percentage = @state.activeTopic.proportion / sumValues * 100
    sampleWords = @state.activeTopic?.topic.words[0...3]
      .map (x) -> x.word
      .concat "…"
      .join ", "
    <div>
      {@renderSVG()}
      <div
        style={cursor: "pointer"}
        onClick={@handleTopicClicked.bind @, @state.activeTopic}>
        <div>{@state.activeTopic?.topic.name ? sampleWords}</div>
        <div>({percentage.toFixed 2}%)</div>
      </div>
    </div>
