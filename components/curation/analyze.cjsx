# @cjsx React.DOM

Create = require "./analyze/create"
React = require "react"

module.exports = React.createClass
  getInitialState: ->
    ingestPill: null
    corpus: null

  handleIngestPillChanged: (pill) ->
    @setState ingestPill: pill

  renderPills: ->
    createA = <a href="#">Process New Ingested Corpus</a>
    selectA = <a href="#">Select Existing Ingested Corpus</a>
    createPill =
      <li onClick={@handleIngestPillChanged.bind @, "create"}>{createA}</li>
    selectPill =
      <li onClick={@handleIngestPillChanged.bind @, "select"}>{selectA}</li>
    switch @state.ingestPill
      when "create"
        createPill = <li className="active">{createA}</li>
      when "select"
        selectPill = <li className="active">{selectA}</li>
    <ul className="nav nav-pills nav-justified" style={marginBottom: "20px"}>
      {createPill}
      {selectPill}
    </ul>

  render: ->
    childView =
      if @state.ingestPill is "create"
        <Create />
    <div className="col-sm-6 col-sm-offset-3">
      {@renderPills()}
      {childView}
    </div>
