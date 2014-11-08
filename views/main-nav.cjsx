# @cjsx React.DOM

React = require "react"

module.exports = React.createClass
  propTypes:
    activeView: React.PropTypes.string
  renderNavItem: (str, key) ->
    if str.toLowerCase() is @props.activeView
      <li key={key} className="active">
        <a href="#">{str}</a>
      </li>
    else
      <li key={key}>
        <a href="/#{str.toLowerCase()}">{str}</a>
      </li>
  render: ->
    <nav className="navbar navbar-default navbar-fixed-top">
      <div className="container">
        <div className="navbar-header">
          <a className="navbar-brand" href="#">STM, Scandinavian Section, UCLA</a>
        </div>
        <ul className="nav navbar-nav navbar-right">
          {@renderNavItem x, i for x, i in ["Curation", "Topics"]}
        </ul>
      </div>
    </nav>
