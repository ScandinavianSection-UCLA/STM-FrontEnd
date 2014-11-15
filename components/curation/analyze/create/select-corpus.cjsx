# @cjsx React.DOM

metadata = require("../../../../async-calls/metadata").calls
nextTick = require "next-tick"
nop = require "nop"
React = require "react"
Typeahead = require "../../../typeahead"

module.exports = React.createClass
  propTypes:
    corpus: React.PropTypes.shape(
      name: React.PropTypes.string.isRequired
      type: React.PropTypes.oneOf(["corpus", "subcorpus"]).isRequired
    )
    onCorpusChange: React.PropTypes.func.isRequired

  getInitialState: ->
    corpusName: @props.corpus?.name ? ""
    corpusType: @props.corpus?.type ? "corpus"
    corpusNameFocused: false
    validatingCorpus: false
    existingCorpora: []
    existingSubcorpora: []

  validateCorpus: ->
    @setState validatingCorpus: true
    metadata.validateCorpus @state.corpusName, @state.corpusType, (result) =>
      @setState validatingCorpus: false
      if result
        @props.onCorpusChange
          name: @state.corpusName
          type: @state.corpusType

  handleCorpusTypeChanged: (type) ->
    @setState corpusType: type
    @props.onCorpusChange null
    nextTick => @validateCorpus()

  renderTypeButtons: ->
    corpusClass = "btn btn-default"
    subcorpusClass = "btn btn-default"
    switch @state.corpusType
      when "corpus"
        corpusClass += "btn btn-primary"
      when "subcorpus"
        subcorpusClass += "btn btn-primary"
    <div className="btn-group btn-group-justified" style={marginBottom: 15}>
      <div className="btn-group">
        <button
          type="button"
          className={corpusClass}
          onClick={@handleCorpusTypeChanged.bind @, "corpus"}>
          Corpus
        </button>
      </div>
      <div className="btn-group">
        <button
          type="button"
          className={subcorpusClass}
          onClick={@handleCorpusTypeChanged.bind @, "subcorpus"}>
          Subcorpus
        </button>
      </div>
    </div>

  handleInputFocused: ->
    @setState
      corpusNameFocused: true
      validatingCorpus: false

  handleTypeaheadBlured: ->
    @setState corpusNameFocused: false
    @props.onCorpusChange null
    nextTick => @validateCorpus()

  renderNonTypeaheadInput: ->
    placeholder =
      if @state.corpusType is "corpus" then "Corpus"
      else if @state.corpusType is "subcorpus" then "Subcorpus"
    divClassName = "form-group"
    accessory = null
    if @state.corpusName is ""
      # no op
    else if @state.validatingCorpus
      divClassName += " has-feedback"
      accessory =
        <i
          className="form-control-feedback fa fa-circle-o-notch fa-spin"
          style={lineHeight: "34px", opacity: 0.5}
        />
    else if @props.corpus?
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
        value={@state.corpusName}
        onChange={nop}
        onFocus={@handleInputFocused}
        placeholder={placeholder}
      />
      {accessory}
    </div>

  handleInputChanged : (value) ->
    @setState corpusName: value

  renderNameBox: ->
    suggestions =
      if @state.corpusType is "corpus" then @state.existingCorpora
      else if @state.corpusType is "subcorpus" then @state.existingSubcorpora
    if @state.corpusNameFocused
      <Typeahead
        value={@state.corpusName}
        onChange={@handleInputChanged}
        onBlur={@handleTypeaheadBlured}
        autoFocus={true}
        suggestions={suggestions}
      />
    else
      @renderNonTypeaheadInput()

  render: ->
    <div className="panel panel-default">
      <div className="panel-heading">
        <h3 className="panel-title">Select Corpus</h3>
      </div>
      <div className="panel-body">
        {@renderTypeButtons()}
        {@renderNameBox()}
      </div>
    </div>

  componentDidMount: ->
    metadata.getCorpora "corpus", (corpora) =>
      @setState existingCorpora: corpora
    metadata.getCorpora "subcorpus", (subcorpora) =>
      @setState existingSubcorpora: subcorpora
    @validateCorpus
