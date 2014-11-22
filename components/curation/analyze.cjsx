# @cjsx React.DOM

Create = require "./analyze/create"
Existing = require "./analyze/existing"
React = require "react"

module.exports = React.createClass
  displayName: "Analyze"
  getInitialState: ->
    ingestPill: null
    initialIngestedCorpus: null

  handleIngestPillChanged: (pill) ->
    @setState ingestPill: pill

  renderPills: ->
    createA = <a href="#">Process New Ingested Corpus</a>
    existingA = <a href="#">Select Existing Ingested Corpus</a>
    createPill =
      <li onClick={@handleIngestPillChanged.bind @, "create"}>{createA}</li>
    existingPill =
      <li onClick={@handleIngestPillChanged.bind @, "existing"}>{existingA}</li>
    switch @state.ingestPill
      when "create"
        createPill = <li className="active">{createA}</li>
      when "existing"
        existingPill = <li className="active">{existingA}</li>
    <ul className="nav nav-pills nav-justified" style={marginBottom: "20px"}>
      {createPill}
      {existingPill}
    </ul>

  handleSwitchToExisting: (icName) ->
    @setState
      ingestPill: "existing"
      initialIngestedCorpus: icName

  render: ->
    childView =
      switch @state.ingestPill
        when "create"
          <Create onSwitchToExisting={@handleSwitchToExisting} />
        when "existing"
          <Existing initialIngestedCorpus={@state.initialIngestedCorpus} />
    <div className="col-sm-6 col-sm-offset-3">
      {@renderPills()}
      {childView}
    </div>
