# @cjsx React.DOM

DeleteCorpus = require "./manage/deleteCorpus"
Files = require "./manage/files"
Metadata = require "./manage/metadata"
React = require "react"

module.exports = React.createClass
  displayName: "Manage"
  getInitialState: ->
    corpus: null

  handleCorpusChanged: (corpus) ->
    @setState corpus: corpus

  handleCorpusDeleted: ->
    @setState corpus: null

  render: ->
    if @state.corpus?
      files = <Files corpus={@state.corpus} />
      deleteCorpus =
        <DeleteCorpus
          corpus={@state.corpus}
          onCorpusDeleted={@handleCorpusDeleted}
        />
    <div className="col-sm-6 col-sm-offset-3">
      <Metadata
        corpus={@state.corpus}
        onCorpusChange={@handleCorpusChanged}
      />
      {files}
      {deleteCorpus}
    </div>
