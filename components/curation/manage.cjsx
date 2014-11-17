# @cjsx React.DOM

Files = require "./manage/files"
Metadata = require "./manage/metadata"
React = require "react"

module.exports = React.createClass
  displayName: "Manage"
  getInitialState: ->
    corpus: null

  handleCorpusChanged: (corpus) ->
    @setState corpus: corpus

  render: ->
    files =
      if @state.corpus?
        <Files corpus={@state.corpus} />
    <div className="col-sm-6 col-sm-offset-3">
      <Metadata
        corpus={@state.corpus}
        onCorpusChange={@handleCorpusChanged}
      />
      {files}
    </div>
