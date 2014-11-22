# @cjsx React.DOM

Inference = require "./create/inference"
Process = require "./create/process"
SelectCorpus = require "./create/select-corpus"
React = require "react"

module.exports = React.createClass
  displayName: "Create"
  propTypes:
    onSwitchToExisting: React.PropTypes.func.isRequired

  getInitialState: ->
    corpus: null
    inference: null
    saveAs: null

  handleCorpusChanged: (corpus) ->
    @setState
      corpus: corpus
      inference: null
      saveAs: null

  handleInferenceChanged: (inference) ->
    @setState
      inference: inference
      saveAs: null

  handleSaveAsChanged: (saveAs) ->
    @setState saveAs: saveAs

  handleProcesStarted: ->
    @props.onSwitchToExisting @state.saveAs

  render: ->
    inference =
      if @state.corpus?
        <Inference
          corpus={@state.corpus}
          inference={@state.inference}
          onInferenceChange={@handleInferenceChanged}
        />
    saveAs =
      if @state.inference?
        <Process
          corpus={@state.corpus}
          inference={@state.inference}
          saveAs={@state.saveAs}
          onSaveAsChange={@handleSaveAsChanged}
          onProcessStart={@handleProcesStarted}
        />
    <div>
      <SelectCorpus
        corpus={@state.corpus}
        onCorpusChange={@handleCorpusChanged}
      />
      {inference}
      {saveAs}
    </div>
