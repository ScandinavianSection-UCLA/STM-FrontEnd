# @cjsx React.DOM

React = require "react"
SelectIngestedCorpus = require "./existing/select-ingested-corpus"

module.exports = React.createClass
  displayName: "Existing"
  propTypes:
    initialIngestedCorpus: React.PropTypes.string

  getInitialState: ->
    ingestedCorpus:
      if @props.initialIngestedCorpus?
        name: @props.initialIngestedCorpus
        status: "unknown"

  handleIngestedCorpusChanged: (ingestedCorpus) ->
    @setState ingestedCorpus: ingestedCorpus

  render: ->
    <div>
      <SelectIngestedCorpus
        ingestedCorpus={@state.ingestedCorpus}
        onIngestedCorpusChange={@handleIngestedCorpusChanged}
      />
    </div>
