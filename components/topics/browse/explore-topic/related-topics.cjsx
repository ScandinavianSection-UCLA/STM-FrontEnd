# @cjsx React.DOM

BinaryPieChart = require "../../../binary-pie-chart"
React = require "react"
Tooltip = require "../../../tooltip"

{
  calls: browseTopics
  isCached: browseTopicsIsCached
} = require "../../../../async-calls/browse-topics"

module.exports = React.createClass
  displayName: "RelatedTopics"
  propTypes:
    location: React.PropTypes.shape(
      ingestedCorpus: React.PropTypes.string.isRequired
      numTopics: React.PropTypes.number.isRequired
      entity: React.PropTypes.shape(
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
    ).isRequired
    onLocationChange: React.PropTypes.func.isRequired

  getInitialState: ->
    @getDefaultState()

  getDefaultState: ->
    similarTopics: null
    loadingSimiliarTopics: false

  componentWillReceiveProps: (props) ->
    @setState @getDefaultState()
    @loadSimilarTopics props if @isSimilarTopicsCached props

  isSimilarTopicsCached: (props) ->
    loc = props.location
    browseTopicsIsCached.getSimilarTopics loc.entity._id

  loadSimilarTopics: (props) ->
    @setState loadingSimiliarTopics: true
    loc = props.location
    browseTopics.getSimilarTopics loc.entity._id, (similarTopics) =>
      @setState
        similarTopics: similarTopics
        loadingSimiliarTopics: false

  handleSimilarTopicClicked: (similarTopic) ->
    @props.onLocationChange
      type: "topic"
      ingestedCorpus: similarTopic.ingestedCorpus
      numTopics: similarTopic.numTopics
      entity: similarTopic.topic

  renderSimilarTopicLI: (similarTopic, i) ->
    sampleWords =
      similarTopic.topic.words[0...3]
        .map (x) -> x.word
        .concat "…"
        .join ", "
    correlation = similarTopic.correlation * 100
    correlation = correlation.toFixed 2
    pieTitle = "Correlation: #{correlation}%"
    pieChart =
      <div className="pull-right">
        <Tooltip placement="right" title={pieTitle}>
          <BinaryPieChart
            size={40}
            radius={18}
            fraction={similarTopic.correlation}
            trueColor="#777"
            falseColor="#eee"
          />
        </Tooltip>
      </div>
    <a
      className="list-group-item"
      key={i}
      href="#"
      onClick={@handleSimilarTopicClicked.bind @, similarTopic}>
      {pieChart}
      <div>{similarTopic.topic.name ? sampleWords}</div>
      <div>
        <small className="text-muted">of </small>
        {similarTopic.ingestedCorpus} ({similarTopic.numTopics} topics)
      </div>
    </a>

  renderSimilarTopicsUL: ->
    return unless @state.similarTopics? and not @state.loadingSimiliarTopics
    unless @state.similarTopics.length is 0
      similarTopics =
        for similarTopic, i in @state.similarTopics
          @renderSimilarTopicLI similarTopic, i
      <div className="list-group">
        {similarTopics}
      </div>
    else
      <div className="panel-body text-center text-muted">
        No related topics
      </div>

  renderLoadingIndicator: ->
    return unless @state.loadingSimiliarTopics
    <div className="panel-body text-center">
      <i
        className="fa fa-circle-o-notch fa-spin"
        style={opacity: 0.5}
      />
    </div>

  renderLoadButton: ->
    return if @state.similarTopics? or @state.loadingSimiliarTopics
    <div className="panel-body">
      <button
        className="col-sm-4 col-sm-offset-4 btn btn-default"
        onClick={@loadSimilarTopics.bind @, @props}>
        Load
      </button>
    </div>

  render: ->
    <div className="panel panel-default">
      <div className="panel-heading">
        <h3 className="panel-title">Related Topics</h3>
      </div>
      {@renderSimilarTopicsUL()}
      {@renderLoadingIndicator()}
      {@renderLoadButton()}
    </div>

  componentDidMount: ->
    @loadSimilarTopics @props if @isSimilarTopicsCached @props
