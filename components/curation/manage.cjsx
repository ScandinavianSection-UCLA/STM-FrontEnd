# @cjsx React.DOM

Files = require "./manage/files"
Metadata = require "./manage/metadata"
React = require "react"

module.exports = React.createClass
  getInitialState: ->
    corpusType: "corpus"
    corpusName: ""
    corpusValid: false

  handleCorpusTypeChanged: (value) ->
    @setState
      corpusType: value
      corpusValid: false

  handleCorpusNameChanged: (value) ->
    @setState corpusName: value

  handleCorpusValidityChanged: (value) ->
    @setState corpusValid: value

  render: ->
    files =
      if @state.corpusValid
        <Files corpusName={@state.corpusName} corpusType={@state.corpusType} />
    <div className="col-sm-6 col-sm-offset-3">
      <Metadata
        corpusType={@state.corpusType}
        corpusName={@state.corpusName}
        corpusValid={@state.corpusValid}
        onCorpusTypeChange={@handleCorpusTypeChanged}
        onCorpusNameChange={@handleCorpusNameChanged}
        onCorpusValidityChange={@handleCorpusValidityChanged}
      />
      {files}
    </div>
