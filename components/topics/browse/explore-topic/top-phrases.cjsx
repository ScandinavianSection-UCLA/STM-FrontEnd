# @cjsx React.DOM

humanFormat = require "human-format"
React = require "react"
Tooltip = require "../../../tooltip"

module.exports = React.createClass
  displayName: "ExploreInferencer"
  propTypes:
    location: React.PropTypes.shape(
      entity: React.PropTypes.shape(
        phrases: React.PropTypes.arrayOf React.PropTypes.shape(
          phrase: React.PropTypes.string.isRequired
          weight: React.PropTypes.number.isRequired
          count: React.PropTypes.number.isRequired
        ).isRequired
      ).isRequired
    ).isRequired

  render: ->
    maxWeight = @props.location.entity.phrases[0].weight
    minWeight = @props.location.entity.phrases[-1..][0].weight
    getFontSize = (weight) ->
      normalizedWeight = (weight - minWeight) / (maxWeight - minWeight)
      15 * (1 + Math.log(1 + normalizedWeight * 9) / Math.log(10)) - 5
    phrases =
      for phrase, i in @props.location.entity.phrases
        style = fontSize: getFontSize phrase.weight
        count = "Count: #{humanFormat phrase.count, unit: ""}"
        <div key={i} style={style}>
          <Tooltip placement="right" title={count}>
            {phrase.phrase}
          </Tooltip>
        </div>
    <div className="panel panel-default">
      <div className="panel-heading">
        <h3 className="panel-title">Top Phrases</h3>
      </div>
      <div className="panel-body text-center">
        {phrases}
      </div>
    </div>
