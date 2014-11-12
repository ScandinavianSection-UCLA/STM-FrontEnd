# @cjsx React.DOM

Metadata = require "./manage/metadata"
React = require "react"

module.exports = React.createClass
  getInitialState: ->
    corpusType: "corpus"
    corpusName: ""
    corpusValid: false

  handleCorpusTypeChanged: (value) ->
    @setState corpusType: value

  handleCorpusNameChanged: (value) ->
    @setState corpusName: value

  handleCorpusValidityChanged: (value) ->
    @setState corpusValid: value

  render: ->
    <div className="col-sm-6 col-sm-offset-3">
      <Metadata
        corpusType={@state.corpusType}
        corpusName={@state.corpusName}
        corpusValid={@state.corpusValid}
        onCorpusTypeChange={@handleCorpusTypeChanged}
        onCorpusNameChange={@handleCorpusNameChanged}
        onCorpusValidityChange={@handleCorpusValidityChanged}
      />
    </div>
