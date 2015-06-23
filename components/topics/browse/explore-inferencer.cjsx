# @cjsx React.DOM

browseTopics = require("../../../async-calls/browse-topics").calls
humanFormat = require "human-format"
React = require "react"

module.exports = React.createClass
  displayName: "ExploreInferencer"
  propTypes:
    location: React.PropTypes.shape(
      ingestedCorpus: React.PropTypes.string.isRequired
      numTopics: React.PropTypes.number.isRequired
    ).isRequired
    onLocationChange: React.PropTypes.func.isRequired

  getInitialState: ->
    topics: null
    loadingTopics: false

  componentWillReceiveProps: (props) ->
    @loadTopics props

  loadTopics: (props) ->
    @setState loadingTopics: true
    browseTopics.getTopicsForIC props.location.ingestedCorpus,
      props.location.numTopics, (topics) =>
        @setState
          topics: topics
          loadingTopics: false

  handleTopicClicked: (topic) ->
    @props.onLocationChange
      type: "topic"
      ingestedCorpus: @props.location.ingestedCorpus
      numTopics: @props.location.numTopics
      entity: topic

  renderTopicLI: (topic, i) ->
    sampleWords =
      topic.words[0...3]
        .map (x) -> x.word
        .concat "…"
        .join ", "
    humanizedTotalTokens = humanFormat topic.totalTokens, unit: ""
    <a
      className="list-group-item"
      key={i}
      href="#"
      onClick={@handleTopicClicked.bind @, topic}>
      <span className="badge">{humanizedTotalTokens}</span>
      {topic.name ? sampleWords}
    </a>

  renderTopicsUL: ->
    return unless @state.topics? and not @state.loadingTopics
    topics =
      @renderTopicLI topic, i for topic, i in @state.topics
    <div className="list-group">
      {topics}
    </div>

  renderLoadingIndicator: ->
    return unless @state.loadingTopics
    <div className="panel-body text-center">
      <i
        className="fa fa-circle-o-notch fa-spin"
        style={opacity: 0.5}
      />
    </div>

  render: ->
    ic = @props.location.ingestedCorpus
    numTopics = @props.location.numTopics
    <div className="row">
      <div className="col-sm-6 col-sm-offset-3">
        <div className="panel panel-default">
          <div className="panel-heading">
            <h3 className="panel-title">Topics in {ic} ({numTopics} topics)</h3>
          </div>
          {@renderTopicsUL()}
          {@renderLoadingIndicator()}
        </div>
      </div>
    </div>

  componentDidMount: ->
    @loadTopics @props
