# @cjsx React.DOM

Inference = require "./create/inference"
Process = require "./create/process"
SelectCorpus = require "./create/select-corpus"
React = require "react"
Preprocessing = require "./create/preprocessing"

module.exports = React.createClass
  displayName: "Create"
  propTypes:
    onSwitchToExisting: React.PropTypes.func.isRequired

  getInitialState: ->
    corpus: null
    inference: null
    saveAs: null
    regexToken: null
    stopwords: null

  handleCorpusChanged: (corpus) ->
    @setState
      corpus: corpus
      inference: null
      saveAs: null
      regexToken: null
      stopwords: null

  handleInferenceChanged: (inference) ->
    @setState
      inference: inference
      saveAs: null

  handleTokenChanged: (regexToken) ->
    @setState regexToken: regexToken

  handleStopwordsChanged: (stopwords) ->
    @setState stopwords: stopwords

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
    regexToken =
      if @state.inference?
        <Preprocessing
          regexToken={@state.regexToken}
          onTokenChange={@handleTokenChanged}
          stopwords={@state.stopwords}
          onStopwordsChange={@handleStopwordsChanged}
        />
    saveAs =
      if @state.inference?
        <Process
          corpus={@state.corpus}
          inference={@state.inference}
          regexToken={@state.regexToken}
          stopwords={@state.stopwords}
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
      {regexToken}
      {saveAs}
    </div>
