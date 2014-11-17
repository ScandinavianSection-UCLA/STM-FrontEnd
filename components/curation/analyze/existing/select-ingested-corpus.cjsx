# @cjsx React.DOM

ingestedCorpusCalls = require("../../../../async-calls/ingested-corpus").calls
nextTick = require "next-tick"
nop = require "nop"
React = require "react"
Typeahead = require "../../../typeahead"

module.exports = React.createClass
  displayName: "SelectIngestedCorpus"
  propTypes:
    ingestedCorpus: React.PropTypes.shape(
      name: React.PropTypes.string.isRequired
      status:
        React.PropTypes.oneOf(["unknown", "processing", "done"]).isRequired
    )
    onIngestedCorpusChange: React.PropTypes.func.isRequired

  getInitialState: ->
    icName: @props.ingestedCorpus?.name ? ""
    icNameFocused: false
    validatingIngestedCorpus: false
    existingIngestedCorpora: []

  validateIngestedCorpus: ->
    @setState validatingIngestedCorpus: true
    ingestedCorpusCalls.validate @state.icName, false, (result) =>
      return unless @state.validatingIngestedCorpus
      return @setState validatingIngestedCorpus: false unless result
      ingestedCorpusCalls.getStatus @state.icName, (status) =>
        return unless @state.validatingIngestedCorpus
        @setState validatingIngestedCorpus: false
        @props.onIngestedCorpusChange
          name: @state.icName
          status: status

  handleInputFocused: ->
    @setState
      icNameFocused: true
      validatingIngestedCorpus: false

  handleTypeaheadBlured: ->
    @setState icNameFocused: false
    if @props.ingestedCorpus?.name isnt @state.icName
      @props.onIngestedCorpusChange null
      nextTick => @validateIngestedCorpus()

  renderNonTypeaheadInput: ->
    divClassName = "form-group"
    accessory = null
    if @state.icName is ""
      # no op
    else if @state.validatingIngestedCorpus
      divClassName += " has-feedback"
      accessory =
        <i
          className="form-control-feedback fa fa-circle-o-notch fa-spin"
          style={lineHeight: "34px", opacity: 0.5}
        />
    else if @props.ingestedCorpus?
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
        value={@state.icName}
        onChange={nop}
        onFocus={@handleInputFocused}
        placeholder="Existing Ingested Corpus"
      />
      {accessory}
    </div>

  handleInputChanged : (value) ->
    @setState icName: value

  renderNameBox: ->
    if @state.icNameFocused
      <Typeahead
        value={@state.icName}
        onChange={@handleInputChanged}
        onBlur={@handleTypeaheadBlured}
        autoFocus={true}
        suggestions={@state.existingIngestedCorpora}
      />
    else
      @renderNonTypeaheadInput()

  render: ->
    <div className="panel panel-default">
      <div className="panel-heading">
        <h3 className="panel-title">Ingested Corpus</h3>
      </div>
      <div className="panel-body">
        {@renderNameBox()}
      </div>
    </div>

  componentDidMount: ->
    ingestedCorpusCalls.getIngestedCorpora false, (ingestedCorpora) =>
      @setState existingIngestedCorpora: ingestedCorpora
    @validateIngestedCorpus()
