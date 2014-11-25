# @cjsx React.DOM

extend = require "extend"
ingestedCorpusCalls = require("../../../../async-calls/ingested-corpus").calls
md5 = require "MD5"
nextTick = require "next-tick"
nop = require "nop"
React = require "react"
socket = require "../../../../socket"
Typeahead = require "../../../typeahead"

module.exports = React.createClass
  displayName: "SelectIngestedCorpus"
  propTypes:
    ingestedCorpus: React.PropTypes.shape(
      name: React.PropTypes.string.isRequired
      corpus: React.PropTypes.shape(
        name: React.PropTypes.string.isRequired
        type: React.PropTypes.oneOf(["corpus", "subcorpus"]).isRequired
      )
      dependsOn: React.PropTypes.string
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
    nextTick =>
      ingestedCorpusCalls.validate @state.icName, false, (result) =>
        return unless @state.validatingIngestedCorpus and @isMounted()
        return @setState validatingIngestedCorpus: false unless result
        ingestedCorpusCalls.getDetails @state.icName, (details) =>
          return unless @state.validatingIngestedCorpus and @isMounted()
          @setState validatingIngestedCorpus: false
          @props.onIngestedCorpusChange
            name: @state.icName
            corpus: details.corpus
            dependsOn: details.dependsOn
            status: details.status
          @listenToChanges() if details.status is "processing"

  listenToChanges: ->
    hash = md5 @props.ingestedCorpus?.name
    ingestedCorpus = @props.ingestedCorpus
    socket.emit "ingest/subscribe", hash
    socket.on "ingest/#{hash}", ({message}) =>
      return unless @isMounted() and @props.ingestedCorpus is ingestedCorpus
      if message is "done"
        ingestedCorpus = extend true, ingestedCorpus
        ingestedCorpus.status = "done"
        @props.onIngestedCorpusChange ingestedCorpus

  handleInputFocused: ->
    @setState
      icNameFocused: true
      validatingIngestedCorpus: false

  handleTypeaheadBlured: ->
    @setState icNameFocused: false
    if @props.ingestedCorpus?.name isnt @state.icName
      @props.onIngestedCorpusChange null
      @validateIngestedCorpus()

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

  renderStatus: ->
    switch @props.ingestedCorpus.status
      when "processing"
        <div className="text-primary">
          <i
            className="fa fa-spin fa-circle-o-notch pull-right"
            style={lineHeight: "inherit"}
          />
          Processing Corpus
        </div>
      when "done"
        corpus = @props.ingestedCorpus.corpus
        infer =
          if @props.ingestedCorpus.dependsOn?
            <span>
              Inferring topics from 
              <strong>{@props.ingestedCorpus.dependsOn}</strong>.
            </span>
          else
            <span>
              Inferring topics on self.
            </span>
        <div>
          <span>
            Ingested from {corpus.type} <strong>{corpus.name}</strong>. 
          </span>
          {infer}
        </div>

  render: ->
    panelBody =
      if @props.ingestedCorpus? and not @state.validatingIngestedCorpus
        <div className="panel-body">
          {@renderNameBox()}
          <hr style={marginBottom: 15, marginTop: 15} />
          {@renderStatus()}
        </div>
      else
        <div className="panel-body">
          {@renderNameBox()}
        </div>
    <div className="panel panel-default">
      <div className="panel-heading">
        <h3 className="panel-title">Ingested Corpus</h3>
      </div>
      {panelBody}
    </div>

  componentDidMount: ->
    ingestedCorpusCalls.getIngestedCorpora false, (ingestedCorpora) =>
      return unless @isMounted()
      @setState existingIngestedCorpora: ingestedCorpora
    @validateIngestedCorpus()
