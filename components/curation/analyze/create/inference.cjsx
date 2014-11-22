# @cjsx React.DOM

deepEqual = require "deep-equal"
ingestedCorpusCalls = require("../../../../async-calls/ingested-corpus").calls
nextTick = require "next-tick"
nop = require "nop"
React = require "react"
Typeahead = require "../../../typeahead"

module.exports = React.createClass
  displayName: "Inference"
  propTypes:
    corpus: React.PropTypes.shape(
      name: React.PropTypes.string.isRequired
      type: React.PropTypes.oneOf(["corpus", "subcorpus"]).isRequired
    ).isRequired
    inference: React.PropTypes.shape(
      inferFrom: React.PropTypes.oneOf(["self", "another"]).isRequired
      dependsOn: React.PropTypes.string
    )
    onInferenceChange: React.PropTypes.func.isRequired

  getInitialState: ->
    @getDefaultState @props

  getDefaultState: (props) ->
    inferFrom: props.inference?.inferFrom ? ""
    dependsOn: props.inference?.dependsOn ? ""
    dependsOnFocused: false
    validatingDependsOn: false
    existingIngestedCorpora: []

  componentWillReceiveProps: (props) ->
    unless deepEqual @props.corpus, props.corpus
      @setState @getDefaultState props
      nextTick => @validateDependsOn()

  validateDependsOn: ->
    @setState validatingDependsOn: true
    ingestedCorpusCalls.validate @state.dependsOn, true, (result) =>
      return unless @state.validatingDependsOn and @isMounted()
      @setState validatingDependsOn: false
      if result
        @props.onInferenceChange
          inferFrom: @state.inferFrom
          dependsOn: @state.dependsOn

  handleInferFromChanged: (inferFrom) ->
    if @props.inference?.inferFrom isnt inferFrom
      @setState
        inferFrom: inferFrom
        dependsOn: ""
      switch inferFrom
        when "self"
          @setState validatingDependsOn: false
          @props.onInferenceChange inferFrom: inferFrom
        when "another"
          @props.onInferenceChange null
          nextTick => @validateDependsOn()

  renderInferFromButtons: ->
    selfClass = "col-sm-6 btn btn-default"
    anotherClass = "col-sm-6 btn btn-default"
    containerStyle =
      paddingLeft: 0
      paddingRight: 0
    switch @state.inferFrom
      when "self"
        selfClass += " active"
      when "another"
        anotherClass += " active"
        containerStyle.marginBottom = 15
    <div className="btn-group col-sm-12" style={containerStyle}>
      <button
        type="button"
        className={selfClass}
        onClick={@handleInferFromChanged.bind @, "self"}>
        Infer topics on self
      </button>
      <button
        type="button"
        className={anotherClass}
        onClick={@handleInferFromChanged.bind @, "another"}>
        Infer topics from …
      </button>
    </div>

  handleInputFocused: ->
    @setState
      dependsOnFocused: true
      validatingDependsOn: false

  handleTypeaheadBlured: ->
    @setState dependsOnFocused: false
    if @props.inference?.dependsOn isnt @state.dependsOn
      @props.onInferenceChange null
      nextTick => @validateDependsOn()

  renderNonTypeaheadInput: ->
    divClassName = "form-group"
    accessory = null
    if @state.dependsOn is ""
      # no op
    else if @state.validatingDependsOn
      divClassName += " has-feedback"
      accessory =
        <i
          className="form-control-feedback fa fa-circle-o-notch fa-spin"
          style={lineHeight: "34px", opacity: 0.5}
        />
    else if @props.inference?
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
      <input
        type="text"
        className="form-control"
        value={@state.dependsOn}
        onChange={nop}
        onFocus={@handleInputFocused}
        placeholder="Existing Ingested Corpus"
      />
      {accessory}
    </div>

  handleInputChanged : (value) ->
    @setState dependsOn: value

  renderNameBox: ->
    if @state.dependsOnFocused
      <Typeahead
        value={@state.dependsOn}
        onChange={@handleInputChanged}
        onBlur={@handleTypeaheadBlured}
        autoFocus={true}
        suggestions={@state.existingIngestedCorpora}
      />
    else
      @renderNonTypeaheadInput()

  render: ->
    dependsOnBox =
      if @state.inferFrom is "another" then @renderNameBox()
    <div className="panel panel-default">
      <div className="panel-heading">
        <h3 className="panel-title">Inference</h3>
      </div>
      <div className="panel-body">
        {@renderInferFromButtons()}
        <div className="clearfix" />
        {dependsOnBox}
      </div>
    </div>

  componentDidMount: ->
    ingestedCorpusCalls.getIngestedCorpora true, (ingestedCorpora) =>
      return unless @isMounted()
      @setState existingIngestedCorpora: ingestedCorpora
    @validateDependsOn()
