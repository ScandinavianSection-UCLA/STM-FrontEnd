# @cjsx React.DOM

browseArticles = require("../../../../async-calls/browse-articles").calls
TopicsPieChart = require "./related-inferencers/topics-pie-chart"
React = require "react"

module.exports = React.createClass
  displayName: "RelatedInferencers"
  propTypes:
    location: React.PropTypes.shape(
      ingestedCorpus: React.PropTypes.string.isRequired
      entity: React.PropTypes.string.isRequired
    ).isRequired
    onLocationChange: React.PropTypes.func.isRequired

  getInitialState: ->
    @getDefaultState()

  getDefaultState: ->
    inferencers: null
    loadingInferencers: false
    selectedInferencer: null

  componentWillReceiveProps: (props) ->
    @setState @getDefaultState()
    @loadingInferencers props

  handleLocationChanged: (location) ->
    @props.onLocationChange location

  loadInferencers: (props) ->
    @setState loadingInferencers: true
    loc = props.location
    browseArticles.getRelatedInferencers loc.ingestedCorpus, loc.entity,
      (inferencers) =>
        @setState
          inferencers: inferencers
          loadingInferencers: false
          selectedInferencer: inferencers[0]

  handleInferencersLIClicked: (inferencer) ->
    @setState selectedInferencer: inferencer

  renderInferencersLI: (inferencer, i) ->
    text = "#{inferencer.ingestedCorpus} (#{inferencer.numTopics} topics)"
    className = "list-group-item"
    if inferencer is @state.selectedInferencer
      <div className="list-group-item active text-center" key={i} href="#">
        <div>{text}</div>
        <TopicsPieChart
          inferencer={inferencer}
          width={230}
          height={230}
          radius={110}
          onLocationChange={@handleLocationChanged}
        />
      </div>
    else
      <a
        className="list-group-item"
        key={i}
        href="#"
        onClick={@handleInferencersLIClicked.bind @, inferencer}>
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
