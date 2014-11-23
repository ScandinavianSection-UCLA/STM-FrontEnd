# @cjsx React.DOM

deepEqual = require "deep-equal"
ingestedCorpusCalls = require("../../../../async-calls/ingested-corpus").calls
md5 = require "MD5"
nextTick = require "next-tick"
React = require "react"
socket = require "../../../../socket"
topicModelingCalls = require("../../../../async-calls/topic-modeling").calls

module.exports = React.createClass
  displayName: "TopicModeling"
  propTypes:
    ingestedCorpus: React.PropTypes.shape(
      name: React.PropTypes.string.isRequired
      dependsOn: React.PropTypes.string
    ).isRequired
    numTopics: React.PropTypes.number
    onNumTopicsChange: React.PropTypes.func.isRequired

  getInitialState: ->
    @getDefaultState @props

  getDefaultState: (props) ->
    inferencerStatus: null
    topicsInferredStatus: null
    numTopics: props.numTopics?.toString() ? ""
    numTopicsFocused: false
    gettingTMStatus: false
    waitingForProcess: false

  componentWillReceiveProps: (props) ->
    unless deepEqual @props.ingestedCorpus, props.ingestedCorpus
      @setState @getDefaultState props
      nextTick => @getTMStatus()

  getTMStatus: ->
    @setState gettingTMStatus: true
    if @state.numTopics.match(/^\d+$/)?
      numTopics = Number @state.numTopics
      ingestedCorpusCalls.getTMStatus @props.ingestedCorpus.name, numTopics,
        (statuses) =>
          return unless @state.gettingTMStatus and @isMounted()
          @setState
            inferencerStatus: statuses.inferencer ? null
            topicsInferredStatus: statuses.topicsInferred ? null
            gettingTMStatus: false
          @props.onNumTopicsChange numTopics
          @listenToChanges()
    else
      @setState
        inferencerStatus: null
        topicsInferredStatus: null
        gettingTMStatus: false
      @props.onNumTopicsChange null

  handleInputFocused: ->
    @setState
      numTopicsFocused: true
      gettingTMStatus: false

  handleInputBlured: ->
    @setState numTopicsFocused: false
    if (
      @props.numTopics isnt Number(@state.numTopics) or
      not @state.numTopics.match(/^\d+$/)?
    )
      @props.onNumTopicsChange null
      nextTick => @getTMStatus() if Number(@state.numTopics) > 0

  handleInputChanged: (event) ->
    @setState numTopics: event.target.value

  handleKeyDown: (event) ->
    handled = true
    if event.keyCode is 13 # enter key
      @refs.input.getDOMNode().blur()
    else
      handled = false
    if handled
      event.stopPropagation()

  renderNumTopicsSelection: ->
    divClassName = "form-group"
    accessory = null
    if @state.numTopics is "" or @state.numTopicsFocused
      # no op
    else if @state.gettingTMStatus
      divClassName += " has-feedback"
      accessory =
        <i
          className="form-control-feedback fa fa-circle-o-notch fa-spin"
          style={lineHeight: "34px", opacity: 0.5}
        />
    else if @props.numTopics?
      divClassName += " has-success has-feedback"
      accessory =
        <i
          className="form-control-feedback fa fa-check"
          style={lineHeight: "34px"}
        />
    else
      divClassName += " has-error has-feedback"
      accessory =
        <i
          className="form-control-feedback fa fa-times"
          style={lineHeight: "34px"}
        />
    divStyle = marginBottom: 0 unless @renderProcessButton()?
    <div className="form-horizontal">
      <div className={divClassName} style={divStyle}>
        <label className="col-sm-4 control-label">Number of Topics</label>
        <div className="col-sm-8">
          <input
            ref="input"
            type="text"
            className="form-control"
            value={@state.numTopics}
            onChange={@handleInputChanged}
            onFocus={@handleInputFocused}
            onBlur={@handleInputBlured}
            onKeyDown={@handleKeyDown}
          />
          {accessory}
        </div>
      </div>
    </div>

  listenToChanges: ->
    name = @props.ingestedCorpus.name
    dependsOn = @props.ingestedCorpus.dependsOn ? name
    inferencerHash = md5 "#{dependsOn}_#{@props.numTopics}"
    topicsInferredHash = md5 "#{name}_#{@props.numTopics}"
    props = @props
    unless @state.inferencerStatus is "done"
      socket.emit "build-inferencer/subscribe", inferencerHash
      socket.on "build-inferencer/#{inferencerHash}", (status) =>
        return unless deepEqual(@props, props) and @isMounted()
        @setState inferencerStatus: status
    unless @state.topicsInferredStatus is "done"
      socket.emit "infer-topic-saturation/subscribe", topicsInferredHash
      socket.on "infer-topic-saturation/#{topicsInferredHash}", (status) =>
        return unless deepEqual(@props, props) and @isMounted()
        @setState
          topicsInferredStatus: status
          waitingForProcess: false

  handleProcessButtonClicked: ->
    @setState waitingForProcess: true
    topicModelingCalls.process @props.ingestedCorpus.name, @props.numTopics

  renderProcessButton: ->
    return unless @props.numTopics?
    unless @state.gettingTMStatus or @state.topicsInferredStatus?
      unless @state.waitingForProcess
        <button
          className="btn btn-primary col-sm-4 col-sm-offset-4"
          onClick={@handleProcessButtonClicked}>
          Process
        </button>
      else
        <button
          className="btn btn-primary col-sm-4 col-sm-offset-4"
          disabled>
          <i
            className="fa fa-circle-o-notch fa-spin fa-fw"
            style={lineHeight: "inherit"}
          />
        </button>

  renderProgress: ->
    return unless @props.numTopics?
    return if @state.gettingTMStatus or not @state.topicsInferredStatus?
    icName = @props.ingestedCorpus.name
    inferencerFor = @props.ingestedCorpus.dependsOn ? icName
    inferencerClassName = "list-group-item"
    topicsInferredClassName = "list-group-item"
    inferencerAttachmentClassName = null
    topicsInferredAttachmentClassName = null
    switch @state.inferencerStatus
      when null
        inferencerClassName += " text-muted"
      when "processing"
        inferencerClassName += " text-primary"
        inferencerAttachmentClassName =
          "fa fa-spin fa-circle-o-notch pull-right"
      when "done"
        inferencerClassName += " text-success"
        inferencerAttachmentClassName =
          "fa fa-check pull-right"
    switch @state.topicsInferredStatus
      when null
        topicsInferredClassName += " text-muted"
      when "processing"
        topicsInferredClassName += " text-primary"
        topicsInferredAttachmentClassName =
          "fa fa-spin fa-circle-o-notch pull-right"
      when "done"
        topicsInferredClassName += " text-success"
        topicsInferredAttachmentClassName =
          "fa fa-check pull-right"
    inferencerAtatchment =
      if inferencerAttachmentClassName?
        <i
          className={inferencerAttachmentClassName}
          style={lineHeight: "inherit"}
        />
    topicsInferredAttachment =
      if topicsInferredAttachmentClassName?
        <i
          className={topicsInferredAttachmentClassName}
          style={lineHeight: "inherit"}
        />
    <ul className="list-group">
      <li className={inferencerClassName}>
        {inferencerAtatchment}
        Building Inferencer for <strong>{inferencerFor}</strong>
      </li>
      <li className={topicsInferredClassName}>
        {topicsInferredAttachment}
        Inferring Topic Saturation in <strong>{icName}</strong>
      </li>
    </ul>

  render: ->
    <div className="panel panel-default">
      <div className="panel-heading">
        <h3 className="panel-title">Topic Modeling</h3>
      </div>
      <div className="panel-body">
        {@renderNumTopicsSelection()}
        {@renderProcessButton()}
      </div>
      {@renderProgress()}
    </div>

  componentDidMount: ->
    @getTMStatus()
