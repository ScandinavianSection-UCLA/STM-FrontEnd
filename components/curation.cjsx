# @cjsx React.DOM

Analyze = require "./curation/analyze"
Manage = require "./curation/manage"
React = require "react"
Tabs = require "./curation/tabs"

module.exports = React.createClass
  getInitialState: ->
    activeTab: "manage"

  handleTabChanged: (activeTab) ->
    @setState activeTab: activeTab

  renderChild: ->
    switch @state.activeTab
      when "manage" then <Manage />
      when "analyze" then <Analyze />

  render: ->
    <div className="container">
      <Tabs activeTab={@state.activeTab} onTabChange={@handleTabChanged} />
      {@renderChild()}
    </div>
