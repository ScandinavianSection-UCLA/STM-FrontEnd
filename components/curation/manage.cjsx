# @cjsx React.DOM

Metadata = require "./manage/metadata"
React = require "react"

module.exports = React.createClass
  getInitialState: ->
    corpusType: "corpus"
    corpusName: ""

  handleCorpusTypeChanged: (type) ->
    @setState corpusType: type

  handleCorpusNameChanged: (value) ->
    @setState corpusName: value

  render: ->
    <div className="col-sm-6 col-sm-offset-3">
      <Metadata
        corpusType={@state.corpusType}
        corpusName={@state.corpusName}
        onCorpusTypeChange={@handleCorpusTypeChanged}
        onCorpusNameChange={@handleCorpusNameChanged}
      />
    </div>
