# @cjsx React.DOM

React = require "react"

module.exports = React.createClass
  displayName: "Tooltip"
  propTypes:
    title: React.PropTypes.string.isRequired
    placement: React.PropTypes.oneOf([
      "top"
      "bottom"
      "left"
      "right"
      "auto"
    ]).isRequired

  render: ->
    <div style={display: "inline-block"}>
      {@props.children}
    </div>

  componentDidMount: ->
    $(@getDOMNode()).tooltip
      title: => @props.title
      placement: => @props.placement
