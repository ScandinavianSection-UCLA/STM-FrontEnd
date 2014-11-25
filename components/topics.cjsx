# @cjsx React.DOM

Browse = require "./topics/browse"
React = require "react"
Tabs = require "./topics/tabs"

module.exports = React.createClass
  displayName: "Topics"
  getInitialState: ->
    activeTab: "browse"

  handleTabChanged: (activeTab) ->
    @setState activeTab: activeTab

  renderChild: ->
    switch @state.activeTab
      when "browse" then <Browse />

  render: ->
    <div className="container">
      <Tabs activeTab={@state.activeTab} onTabChange={@handleTabChanged} />
      {@renderChild()}
    </div>
