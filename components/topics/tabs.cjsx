# @cjsx React.DOM

React = require "react"

navTabs =
  browse: "Browse"
  graph: "Graph"

module.exports = React.createClass
  displayName: "Tabs"
  propTypes:
    activeTab: React.PropTypes.oneOf(Object.keys navTabs).isRequired
    onTabChange: React.PropTypes.func.isRequired

  renderNavTab: (key, str) ->
    a = <a href="#" onClick={=> @props.onTabChange key}>{str}</a>
    if key is @props.activeTab
      <li role="presentation" key={key} className="active">{a}</li>
    else
      <li role="presentation" key={key}>{a}</li>

  render: ->
    <ul className="nav nav-tabs" style={marginBottom: 20} role="tablist">
      {@renderNavTab id, title for id, title of navTabs}
    </ul>
