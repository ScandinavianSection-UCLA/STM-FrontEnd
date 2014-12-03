# @cjsx React.DOM

React = require "react"

module.exports = React.createClass
  displayName: "BinaryPieChart"
  propTypes:
    size: React.PropTypes.number.isRequired
    radius: React.PropTypes.number.isRequired
    fraction: React.PropTypes.number.isRequired
    trueColor: React.PropTypes.string.isRequired
    falseColor: React.PropTypes.string

  renderPath: ->
    fraction = 100 * @props.fraction
    fraction = 99.99 if fraction > 99.99
    size = @props.size
    center = size / 2
    radius = @props.radius
    largeArcFlag = if fraction < 50 then 0 else 1
    dx = center + radius * Math.cos(fraction * Math.PI / 50)
    dy = center - radius * Math.sin(fraction * Math.PI / 50)
    d =
      """
      M #{center} #{center}
      L #{center + radius} #{center}
      A #{radius} #{radius} 0 #{largeArcFlag} 0 #{dx} #{dy}
      Z
      """
    style = fill: @props.trueColor
    <path d={d} style={style} />

  renderCircle: ->
    return unless @props.falseColor?
    center = @props.size / 2
    style = fill: @props.falseColor
    <circle cx={center} cy={center} r={@props.radius} style={style} />

  render: ->
    <svg height={@props.size} width={@props.size}>
      {@renderCircle()}
      {@renderPath()}
    </svg>
