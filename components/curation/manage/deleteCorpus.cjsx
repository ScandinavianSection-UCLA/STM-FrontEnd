# @cjsx React.DOM
corpusCalls = require("../../../async-calls/corpus").calls
React = require "react"

module.exports = React.createClass
  displayName: "DeleteCorpus"
  propTypes:
    corpus: React.PropTypes.shape(
      name: React.PropTypes.string.isRequired
      type: React.PropTypes.oneOf(["corpus", "subcorpus"]).isRequired
    ).isRequired
    onCorpusDeleted: React.PropTypes.func

  getInitialState: ->
    confirmation: false

  handleDeleteClicked: ->
    @setState confirmation: true

  handleConfirmDeleteClicked: ->
    corpusCalls.deleteCorpus @props.corpus.name, @props.corpus.type, =>
      @props.onCorpusDeleted()

  render: ->
    corpusType =
      switch @props.corpus.type
        when "corpus" then "Corpus"
        when "subcorpus" then "Subcorpus"
    panelBody =
      unless @state.confirmation
        <div className="panel-body">
          <button
            className="btn btn-danger col-sm-4 col-sm-offset-4"
            onClick={@handleDeleteClicked}>
            Delete
          </button>
        </div>
      else
        <div className="panel-body">
          <div className="alert alert-warning" role="alert">
            <strong>Warning!</strong> This will remove the entire corpus with
            its files, related ingested corpora, inferencers and modelled
            topics.
          </div>
          <button
            className="btn btn-danger col-sm-4 col-sm-offset-4"
            onClick={@handleConfirmDeleteClicked}>
            Delete Anyway
          </button>
        </div>
    <div className="panel panel-default">
      <div className="panel-heading">
        <h3 className="panel-title">Delete {corpusType}</h3>
      </div>
      {panelBody}
    </div>
