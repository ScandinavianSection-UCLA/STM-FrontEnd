# @cjsx React.DOM

browseTopics = require("../../../async-calls/browse-topics").calls
extend = require "extend"
nextTick = require "next-tick"
nop = require "nop"
React = require "react"
Typeahead = require "../../typeahead"

module.exports = React.createClass
  displayName: "MakeSelection"
  propTypes:
    location: React.PropTypes.shape(
      type: React.PropTypes.oneOf(["topic", "article"]).isRequired
      ingestedCorpus: React.PropTypes.string
    ).isRequired
    onLocationChange: React.PropTypes.func.isRequired

  getInitialState: ->
    extend @getDefaultState(@props),
      existingICInferencers: []
      existingIC: []
      existingNumTopics: []

  getDefaultState: (props) ->
    icName: props.location.ingestedCorpus ? ""
    icNameFocused: false
    validatingICName: false
    numTopics: ""
    numTopicsFocused: false
    validatingNumTopics: false

  componentWillReceiveProps: (props) ->
    unless (
      @props.location.type is props.location.type and
      @props.location.ingestedCorpus is props.location.ingestedCorpus
    )
      if @skipResetState
        delete @skipResetState
      else
        @setState @getDefaultState props
      nextTick => @fetchExistingNumTopics()

  fetchExistingNumTopics: ->
    @setState existingNumTopics: []
    ic = @props.location.ingestedCorpus
    if @props.location.type is "topic" and ic?
      browseTopics.getNumTopicsForIC ic, (numTopics) =>
        @setState existingNumTopics: numTopics.map (x) -> x.toString()

  handleTypeChanged: (type) ->
    if @props.location.type isnt type
      @props.onLocationChange
        type: type
      @setState
        icName: ""
        numTopics: ""
        validatingNumTopics: false
      @validateICName()

  renderTypeButtons: ->
    topicClass = "col-sm-6 btn btn-default"
    articleClass = "col-sm-6 btn btn-default"
    switch @props.location.type
      when "topic"
        topicClass += " active"
      when "article"
        articleClass += " active"
    <div
      className="btn-group col-sm-12"
      style={marginBottom: 15, paddingLeft: 0, paddingRight: 0}>
      <button
        type="button"
        className={topicClass}
        onClick={@handleTypeChanged.bind @, "topic"}>
        Topics
      </button>
      <button
        type="button"
        className={articleClass}
        onClick={@handleTypeChanged.bind @, "article"}>
        Articles
      </button>
    </div>

  validateICName: ->
    @setState validatingICName: true
    nextTick =>
      browseTopics.validateICName @state.icName, (result) =>
        return unless @state.validatingICName and @isMounted()
        @setState validatingICName: false
        if result
          @skipResetState = true
          @props.onLocationChange
            type: @props.location.type
            ingestedCorpus: @state.icName

  handleICNameFocused: ->
    @setState
      icNameFocused: true
      validatingICName: false

  handleICNameTypeaheadBlured: ->
    @setState icNameFocused: false
    if @props.location.ingestedCorpus isnt @state.icName
      @props.onLocationChange
        type: @props.location.type
      @setState
        numTopics: ""
        validatingNumTopics: false
      @validateICName()

  renderICNameNonTypeaheadInput: ->
    divClassName = "form-group"
    accessory = null
    if @state.icName is ""
      # no op
    else if @state.validatingICName
      divClassName += " has-feedback"
      accessory =
        <i
          className="form-control-feedback fa fa-circle-o-notch fa-spin"
          style={lineHeight: "34px", opacity: 0.5}
        />
    else if @props.location.ingestedCorpus?
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
    icLabel =
      switch @props.location.type
        when "topic" then "Inferencer"
        when "article" then "Ingested Corpus"
    divStyle = marginBottom: 0 unless @renderNumTopics()?
    <div className={divClassName} style={divStyle}>
      <label className="col-sm-4 control-label">{icLabel}</label>
      <div className="col-sm-8">
        <input
          type="text"
          className="form-control col-sm-8"
          value={@state.icName}
          onChange={nop}
          onFocus={@handleICNameFocused}
        />
        {accessory}
      </div>
    </div>

  handleICNameInputChanged : (value) ->
    @setState icName: value

  renderICName: ->
    if @state.icNameFocused
      icLabel =
        switch @props.location.type
          when "topic" then "Inferencer"
          when "article" then "Ingested Corpus"
      divStyle = marginBottom: 0 unless @renderNumTopics()?
      suggestions =
        switch @props.location.type
          when "topic" then @state.existingICInferencers
          when "article" then @state.existingIC
      <div className="form-group" style={divStyle}>
        <label className="col-sm-4 control-label">{icLabel}</label>
        <div className="col-sm-8">
          <Typeahead
            value={@state.icName}
            className="col-sm-8"
            onChange={@handleICNameInputChanged}
            onBlur={@handleICNameTypeaheadBlured}
            autoFocus={true}
            suggestions={suggestions}
          />
        </div>
      </div>
    else
      @renderICNameNonTypeaheadInput()

  validateNumTopics: ->
    return unless @state.numTopics.match(/^\d+$/)?
    numTopics = Number @state.numTopics
    @setState validatingNumTopics: true
    nextTick =>
      unless @state.numTopics.match(/^\d+$/)?
        return @setState validatingNumTopics: false
      numTopics = Number @state.numTopics
      browseTopics.validateNumTopicsForIC @state.icName, numTopics, (result) =>
        return unless @state.validatingNumTopics and @isMounted()
        @setState validatingNumTopics: false
        if result
          @props.onLocationChange
            type: @props.location.type
            ingestedCorpus: @state.icName
            numTopics: Number numTopics

  handleNumTopicsFocused: ->
    @setState
      numTopicsFocused: true
      validatingNumTopics: false

  handleNumTopicsTypeaheadBlured: ->
    @setState numTopicsFocused: false
    if @props.location.numTopics isnt Number(@state.numTopics)
      @props.onLocationChange
        type: @props.location.type
        ingestedCorpus: @props.location.ingestedCorpus
      @validateNumTopics()

  renderNumTopicsNonTypeaheadInput: ->
    divClassName = "form-group"
    accessory = null
    if @state.numTopics is ""
      # no op
    else if @state.validatingNumTopics
      divClassName += " has-feedback"
      accessory =
        <i
          className="form-control-feedback fa fa-circle-o-notch fa-spin"
          style={lineHeight: "34px", opacity: 0.5}
        />
    else if @props.location.numTopics?
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
    <div className={divClassName} style={marginBottom: 0}>
      <label className="col-sm-4 control-label">Number of Topics</label>
      <div className="col-sm-8">
        <input
          type="text"
          className="form-control col-sm-8"
          value={@state.numTopics}
          onChange={nop}
          onFocus={@handleNumTopicsFocused}
        />
        {accessory}
      </div>
    </div>

  handleNumTopicsInputChanged : (value) ->
    @setState numTopics: value

  renderNumTopics: ->
    return unless @props.location.ingestedCorpus?
    if @state.numTopicsFocused
      <div className="form-group" style={marginBottom: 0}>
        <label className="col-sm-4 control-label">Number of Topics</label>
        <div className="col-sm-8">
          <Typeahead
            value={@state.numTopics}
            className="col-sm-8"
            onChange={@handleNumTopicsInputChanged}
            onBlur={@handleNumTopicsTypeaheadBlured}
            autoFocus={true}
            suggestions={@state.existingNumTopics}
          />
        </div>
      </div>
    else
      @renderNumTopicsNonTypeaheadInput()

  render: ->
    <div className="col-sm-6 col-sm-offset-3">
      <div className="panel panel-default">
        <div className="panel-body">
          {@renderTypeButtons()}
          <div className="form-horizontal clearfix">
            {@renderICName()}
            {@renderNumTopics()}
          </div>
        </div>
      </div>
    </div>

  componentDidMount: ->
    browseTopics.getIngestedCorpora (ingestedCorpora) =>
      return unless @isMounted()
      @setState existingICInferencers: ingestedCorpora
    @validateICName()
    @fetchExistingNumTopics()
