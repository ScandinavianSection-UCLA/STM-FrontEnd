# @cjsx React.DOM

corpusCalls = require("../../../../async-calls/corpus").calls
nextTick = require "next-tick"
nop = require "nop"
React = require "react"
Typeahead = require "../../../typeahead"

module.exports = React.createClass
  displayName: "SelectCorpus"
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
    corpusCalls.validate @state.corpusName, @state.corpusType, (result) =>
      return unless @state.validatingCorpus
      @setState validatingCorpus: false
      if result
        @props.onCorpusChange
          name: @state.corpusName
          type: @state.corpusType

  handleCorpusTypeChanged: (type) ->
    @setState corpusType: type
    if @props.corpus?.type isnt type
      @props.onCorpusChange null
      nextTick => @validateCorpus()

  renderTypeButtons: ->
    corpusClass = "col-sm-6 btn btn-default"
    subcorpusClass = "col-sm-6 btn btn-default"
    switch @state.corpusType
      when "corpus"
        corpusClass += " active"
      when "subcorpus"
        subcorpusClass += " active"
    <div
      className="btn-group col-sm-12"
      style={marginBottom: 15, paddingLeft: 0, paddingRight: 0}>
      <button
        type="button"
        className={corpusClass}
        onClick={@handleCorpusTypeChanged.bind @, "corpus"}>
        Corpus
      </button>
      <button
        type="button"
        className={subcorpusClass}
        onClick={@handleCorpusTypeChanged.bind @, "subcorpus"}>
        Subcorpus
      </button>
    </div>

  handleInputFocused: ->
    @setState
      corpusNameFocused: true
      validatingCorpus: false

  handleTypeaheadBlured: ->
    @setState corpusNameFocused: false
    if @props.corpus?.name isnt @state.corpusName
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
        <div className="clearfix" />
        {@renderNameBox()}
      </div>
    </div>

  componentDidMount: ->
    corpusCalls.getCorpora "corpus", (corpora) =>
      @setState existingCorpora: corpora
    corpusCalls.getCorpora "subcorpus", (subcorpora) =>
      @setState existingSubcorpora: subcorpora
    @validateCorpus()
