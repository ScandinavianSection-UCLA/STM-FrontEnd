# @cjsx React.DOM

humanFormat = require "human-format"
React = require "react"
Tooltip = require "../../../tooltip"

module.exports = React.createClass
  displayName: "ExploreInferencer"
  propTypes:
    location: React.PropTypes.shape(
      entity: React.PropTypes.shape(
        words: React.PropTypes.arrayOf React.PropTypes.shape(
          word: React.PropTypes.string.isRequired
          weight: React.PropTypes.number.isRequired
          count: React.PropTypes.number.isRequired
        ).isRequired
      ).isRequired
    ).isRequired

  render: ->
    maxWeight = @props.location.entity.words[0].weight
    minWeight = @props.location.entity.words[-1..][0].weight
    getFontSize = (weight) ->
      normalizedWeight = (weight - minWeight) / (maxWeight - minWeight)
      15 * (1 + Math.log(1 + normalizedWeight * 9) / Math.log(10)) - 5
    words =
      for word, i in @props.location.entity.words
        style = fontSize: getFontSize word.weight
        count = "Count: #{humanFormat word.count, unit: ""}"
        <div key={i} style={style}>
          <Tooltip placement="right" title={count}>
            {word.word}
          </Tooltip>
        </div>
    <div className="panel panel-default">
      <div className="panel-heading">
        <h3 className="panel-title">Top Words</h3>
      </div>
      <div className="panel-body text-center">
        {words}
      </div>
    </div>
