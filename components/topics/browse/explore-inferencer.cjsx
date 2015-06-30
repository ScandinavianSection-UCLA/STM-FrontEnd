# @cjsx React.DOM

asyncCaller = require "../../../async-caller"
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
    editMode: false

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
    if @state.editMode
      browseTopics.updateTopicHidden topic._id, !topic.hidden, (result) =>
        return unless result
        asyncCaller.resetAllCaches()
        topic.hidden = !topic.hidden
        @setState
          topics: @state.topics
    else
      @props.onLocationChange
        type: "topic"
        ingestedCorpus: @props.location.ingestedCorpus
        numTopics: @props.location.numTopics
        entity: topic

  handleEditModeToggled: ->
    @setState editMode: not @state.editMode

  renderTopicLI: (topic, i) ->
    sampleWords =
      topic.words[0...3]
        .map (x) -> x.word
        .concat "…"
        .join ", "
    if @state.editMode
      if topic.hidden
        iClassName = "fa fa-fw fa-cross pull-right"
        liClassName = "list-group-item"
      else
        iClassName = "fa fa-fw fa-check pull-right"
        liClassName = "list-group-item list-group-item-success"
      editModeIcon =
        <i className={iClassName} style={lineHeight: "inherit"} />
    else
      return if topic.hidden
      liClassName = "list-group-item"
      humanizedTotalTokens = humanFormat topic.totalTokens, unit: ""
      badge = <span className="badge">{humanizedTotalTokens}</span>
    <a
      className={liClassName}
      key={i}
      href="#"
      onClick={@handleTopicClicked.bind @, topic}>
      {editModeIcon}
      {badge}
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
    if @state.editMode
      iClassName = "fa fa-fw fa-check"
      btnClassName = "btn btn-success btn-sm pull-right"
    else
      iClassName = "fa fa-fw fa-pencil"
      btnClassName = "btn btn-primary btn-sm pull-right"
    <div className="row">
      <div className="col-sm-6 col-sm-offset-3">
        <div className="panel panel-default">
          <div className="panel-heading">
            <button
              className={btnClassName}
              style={marginTop: -3}
              onClick={@handleEditModeToggled}>
              <i className={iClassName} />
            </button>
            <h3 className="panel-title">Topics in {ic} ({numTopics} topics)</h3>
          </div>
          {@renderTopicsUL()}
          {@renderLoadingIndicator()}
        </div>
      </div>
    </div>

  componentDidMount: ->
    @loadTopics @props
