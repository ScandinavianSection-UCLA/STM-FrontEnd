# @cjsx React.DOM

React = require "react"

module.exports = React.createClass
  displayName: "Breadcrumb"
  propTypes:
    location: React.PropTypes.shape(
      type: React.PropTypes.oneOf(["topic", "article"]).isRequired
      ingestedCorpus: React.PropTypes.string
      numTopics: React.PropTypes.number
      entity: React.PropTypes.string
    ).isRequired
    onLocationChange: React.PropTypes.func.isRequired

  handleTypeClicked: ->
    @props.onLocationChange
      type: @props.location.type

  handleICCLicked: ->
    @props.onLocationChange
      type: @props.location.type
      ingestedCorpus: @props.location.ingestedCorpus

  handleNumClicked: ->
    @props.onLocationChange
      type: @props.location.type
      ingestedCorpus: @props.location.ingestedCorpus
      numTopics: @props.location.numTopics

  render: ->
    loc = @props.location
    homeLI =
      <li onClick={@handleTypeClicked}>
        <a href="#"><i className="fa fa-home" /></a>
      </li>
    typeText =
      switch loc.type
        when "topic" then "Topics"
        when "article" then "Articles"
    typeLI =
      if loc.ingestedCorpus?
        <li onClick={@handleTypeClicked}>
          <a href="#">{typeText}</a>
        </li>
      else
        <li className="active">
          {typeText}
        </li>
    icLI =
      unless loc.ingestedCorpus?
        # no op
      else if (
        loc.type is "topic" and loc.numTopics? or
        loc.type is "article" and loc.entity?
      )
        <li onClick={@handleICCLicked}>
          <a href="#">{loc.ingestedCorpus}</a>
        </li>
      else
        <li className="active">
          {loc.ingestedCorpus}
        </li>
    numLI =
      unless loc.numTopics?
        # no op
      else if loc.entity?
         <li onClick={@handleNumClicked}>
          <a href="#">Number of Topics: {loc.numTopics}</a>
        </li>
      else
        <li className="active">
          Number of Topics: {loc.numTopics}
        </li>
    entityLI =
      unless loc.entity?
        # no op
      else
        <li className="active">
          {loc.entity}
        </li>
    <ol className="breadcrumb">
      {homeLI}
      {typeLI}
      {icLI}
      {numLI}
      {entityLI}
    </ol>
