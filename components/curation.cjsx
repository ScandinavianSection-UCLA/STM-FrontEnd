# @cjsx React.DOM

Manage = require "./curation/manage"
React = require "react"
Tabs = require "./curation/tabs"

module.exports = React.createClass
  getInitialState: ->
    activeTab: "manage"

  handleTabChanged: (activeTab) ->
    @setState activeTab: activeTab

  renderChild: ->
    if @state.activeTab is "manage"
      <Manage />

  render: ->
    <div className="container">
      <Tabs activeTab={@state.activeTab} onTabChange={@handleTabChanged} />
      {@renderChild()}
    </div>
