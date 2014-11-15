# @cjsx React.DOM

Inference = require "./create/inference"
SelectCorpus = require "./create/select-corpus"
React = require "react"

module.exports = React.createClass
  getInitialState: ->
    corpus: null

  handleCorpusChanged: (corpus) ->
    @setState corpus: corpus

  render: ->
    inference = <Inference /> if @state.corpus?
    <div>
      <SelectCorpus
        corpus={@state.corpus}
        onCorpusChange={@handleCorpusChanged}
      />
      {inference}
    </div>
