# @cjsx React.DOM

metadata = require("../../../async-calls/metadata").calls
React = require "react"
Typeahead = require "../../typeahead"

module.exports = React.createClass
  propTypes:
    corpusType: React.PropTypes.oneOf(["corpus", "subcorpus"]).isRequired
    corpusName: React.PropTypes.string
    onCorpusTypeChange: React.PropTypes.func.isRequired
    onCorpusNameChange: React.PropTypes.func.isRequired

  getInitialState: ->
    corpusNameFocused: false
    existingCorpora: []
    existingSubcorpora: []
    validatingCorpus: false
    corpusValid: false

  componentDidMount: ->
    metadata.getCorpora "corpus", (corpora) =>
      @setState existingCorpora: corpora
    metadata.getCorpora "subcorpus", (subcorpora) =>
      @setState existingSubcorpora: subcorpora

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
    <div className="btn-group btn-group-justified" style={marginBottom: 10}>
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
    @setState corpusNameFocused: true, validatingCorpus: false

  handleInputBlured: ->
    @setState corpusNameFocused: false, validatingCorpus: true
    metadata.validateCorpus @props.corpusName, @props.corpusType, (valid) =>
      @setState validatingCorpus: false, corpusValid: valid

  renderNameBox: ->
    placeholder = null
    suggestions = null
    if @props.corpusType is "corpus"
      placeholder = "Corpus"
      suggestions = @state.existingCorpora
    else if @props.corpusType is "subcorpus"
      placeholder = "Subcorpus"
      suggestions = @state.existingSubcorpora
    if @state.corpusNameFocused
      <Typeahead
        value={@props.corpusName}
        onChange={@props.onCorpusNameChange}
        onBlur={@handleInputBlured}
        autoFocus={true}
        suggestions={suggestions}
      />
    else
      <div>
        <input
          type="text"
          className="form-control"
          value={@props.corpusName}
          onChange={@props.onCorpusNameChange}
          onFocus={@handleInputFocused}
          placeholder={placeholder}
        />
      </div>

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

###
        <div
          className="form-group has-success has-feedback"
          style={marginBottom: 0}>
          <input type="text" className="form-control" />
          <i
            className="form-control-feedback fa fa-check"
            style={lineHeight: "34px"}
          />
        </div>
###
