# @cjsx React.DOM

metadata = require("../../../async-calls/metadata").calls
nextTick = require "next-tick"
nop = require "nop"
React = require "react"
Typeahead = require "../../typeahead"

module.exports = React.createClass
  propTypes:
    corpusType: React.PropTypes.oneOf(["corpus", "subcorpus"]).isRequired
    corpusName: React.PropTypes.string
    corpusValid: React.PropTypes.bool
    onCorpusTypeChange: React.PropTypes.func.isRequired
    onCorpusNameChange: React.PropTypes.func.isRequired
    onCorpusValidityChange: React.PropTypes.func.isRequired

  getInitialState: ->
    corpusName: @props.corpusName
    corpusNameFocused: false
    existingCorpora: []
    existingSubcorpora: []
    validatingCorpus: false

  componentDidMount: ->
    metadata.getCorpora "corpus", (corpora) =>
      @setState existingCorpora: corpora
    metadata.getCorpora "subcorpus", (subcorpora) =>
      @setState existingSubcorpora: subcorpora
    @validateCorpus @props

  componentWillReceiveProps: (props) ->
    @validateCorpus props if (
      @props.corpusName isnt props.corpusName or
      @props.corpusType isnt props.corpusType
    )

  validateCorpus: (props) ->
    @setState validatingCorpus: true
    metadata.validateCorpus props.corpusName, props.corpusType, (result) =>
      @setState validatingCorpus: false
      @props.onCorpusValidityChange result

  handleCorpusTypeChanged: (type) ->
    @props.onCorpusTypeChange type

  renderTypeButtons: ->
    corpusClass = "btn"
    subcorpusClass = "btn"
    if @props.corpusType is "corpus"
      corpusClass += " btn-primary"
      subcorpusClass += " btn-default"
    else if @props.corpusType is "subcorpus"
      corpusClass += " btn-default"
      subcorpusClass += " btn-primary"    
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
    nextTick => @props.onCorpusNameChange @state.corpusName

  handleInsertCorpus: ->
    newCorpus =
      name: @props.corpusName
      type: @props.corpusType
    metadata.insertCorpus newCorpus.name, newCorpus.type, (result) =>
      if result
        @props.onCorpusValidityChange true
        if newCorpus.type is "corpus"
          @setState
            existingCorpora:
              @state.existingCorpora.concat [newCorpus.name]
        else if newCorpus.type is "subcorpus"
          @setState
            existingSubcorpora:
              @state.existingSubcorpora.concat [newCorpus.name]

  renderNonTypeaheadInput: ->
    placeholder =
      if @props.corpusType is "corpus" then "Corpus"
      else if @props.corpusType is "subcorpus" then "Subcorpus"
    divClassName = "form-group"
    accessory = null
    if @props.corpusName is ""
      # no op
    else if @state.validatingCorpus
      divClassName += " has-feedback"
      accessory =
        <i
          className="form-control-feedback fa fa-circle-o-notch fa-spin"
          style={lineHeight: "34px", opacity: 0.5}
        />
    else if @props.corpusValid
      divClassName += " has-success has-feedback"
      accessory =
        <i
          className="form-control-feedback fa fa-check"
          style={lineHeight: "34px"}
        />
    else
      divClassName += " input-group"
      accessory =
        <span className="input-group-btn">
          <button
            className="btn btn-primary"
            type="button"
            onClick={@handleInsertCorpus}>
            <i className="fa fa-plus" style={lineHeight: "20px"} />
          </button>
        </span>
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
      if @props.corpusType is "corpus" then @state.existingCorpora
      else if @props.corpusType is "subcorpus" then @state.existingSubcorpora
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
        <h3 className="panel-title">Metadata</h3>
      </div>
      <div className="panel-body">
        {@renderTypeButtons()}
        {@renderNameBox()}
      </div>
    </div>
