# @cjsx React.DOM

React = require "react"

module.exports = React.createClass
  displayName: "Tooltip"
  propTypes:
    title: React.PropTypes.oneOfType([
      React.PropTypes.string
      React.PropTypes.element
    ]).isRequired
    placement: React.PropTypes.oneOf([
      "top"
      "bottom"
      "left"
      "right"
      "auto"
    ]).isRequired

  render: ->
    if React.isValidElement @props.children
      @props.children
    else
      <div style={display: "inline-block"}>
        {@props.children}
      </div>

  componentDidMount: ->
    $(@getDOMNode()).tooltip
      title: =>
        title = @props.title
        title = <span>{title}</span> unless React.isValidElement title
        React.renderToString title
      placement: => @props.placement
      container: "body"
      html: true
