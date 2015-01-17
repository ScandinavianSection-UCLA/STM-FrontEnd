# @cjsx React.DOM

browseArticles = require("../../../../async-calls/browse-articles").calls
deepEqual = require "deep-equal"
TopicsPieChart = require "./related-inferencers/topics-pie-chart"
React = require "react"

module.exports = React.createClass
  displayName: "RelatedInferencers"
  propTypes:
    location: React.PropTypes.shape(
      ingestedCorpus: React.PropTypes.string.isRequired
      entity: React.PropTypes.shape(
        _id: React.PropTypes.string.isRequired
        name: React.PropTypes.string.isRequired
      ).isRequired
    ).isRequired
    onLocationChange: React.PropTypes.func.isRequired
    onHighlightedTopicChange: React.PropTypes.func.isRequired

  getInitialState: ->
    @getDefaultState()

  getDefaultState: ->
    inferencers: null
    loadingInferencers: false
    selectedInferencer: null

  componentWillReceiveProps: (props) ->
    unless deepEqual @props.location, props.location
      @setState @getDefaultState()
      @loadInferencers props

  handleLocationChanged: (location) ->
    @props.onLocationChange location

  loadInferencers: (props) ->
    @setState loadingInferencers: true
    loc = props.location
    browseArticles.getRelatedInferencers loc.entity._id, (inferencers) =>
      @setState
        inferencers: inferencers
        loadingInferencers: false
        selectedInferencer: inferencers[0]

  handleInferencersLIClicked: (inferencer) ->
    @setState selectedInferencer: inferencer

  handleHighlightedTopicChanged: (topic) ->
    @props.onHighlightedTopicChange topic

  renderInferencersLI: (inferencer, i) ->
    text = "#{inferencer.ingestedCorpus} (#{inferencer.numTopics} topics)"
    className = "list-group-item"
    if inferencer is @state.selectedInferencer
      <div className="list-group-item active text-center" key={i} href="#">
        <div style={fontWeight: 500}>{text}</div>
        <TopicsPieChart
          inferencer={inferencer}
          width={230}
          height={230}
          radius={110}
          onLocationChange={@handleLocationChanged}
          onHighlightedTopicChange={@handleHighlightedTopicChanged}
        />
      </div>
    else
      <a
        className="list-group-item text-center"
        key={i}
        href="#"
        onClick={@handleInferencersLIClicked.bind @, inferencer}
        style={fontWeight: 500}>
        {text}
      </a>

  renderInferencersUL: ->
    return unless @state.inferencers? and not @state.loadingInferencers
    inferencersUL =
      for inferencer, i in @state.inferencers
        @renderInferencersLI inferencer, i
    <div className="list-group">
      {inferencersUL}
    </div>

  renderLoadingIndicator: ->
    return unless @state.loadingInferencers
    <div className="panel-body text-center">
      <i
        className="fa fa-circle-o-notch fa-spin"
        style={opacity: 0.5}
      />
    </div>

  render: ->
    <div className="panel panel-default">
      <div className="panel-heading">
        <h3 className="panel-title">Related Inferencers</h3>
      </div>
      {@renderInferencersUL()}
      {@renderLoadingIndicator()}
    </div>

  componentDidMount: ->
    @loadInferencers @props
