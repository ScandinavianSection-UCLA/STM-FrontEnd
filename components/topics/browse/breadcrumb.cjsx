# @cjsx React.DOM

React = require "react"

module.exports = React.createClass
  displayName: "Breadcrumb"
  propTypes:
    location: React.PropTypes.shape(
      type: React.PropTypes.oneOf(["topic", "article"]).isRequired
      ingestedCorpus: React.PropTypes.string
      numTopics: React.PropTypes.number
      entity: React.PropTypes.oneOfType [
        React.PropTypes.shape
          _id: React.PropTypes.string.isRequired
          name: React.PropTypes.string.isRequired
        React.PropTypes.shape
          _id: React.PropTypes.string.isRequired
          words: React.PropTypes.arrayOf React.PropTypes.shape(
            word: React.PropTypes.string.isRequired
          ).isRequired
      ]
    ).isRequired
    onLocationChange: React.PropTypes.func.isRequired
    graphSeeds: React.PropTypes.shape(
      topics: React.PropTypes.arrayOf React.PropTypes.string
      articles: React.PropTypes.arrayOf React.PropTypes.string
    ).isRequired
    onGraphSeedsChange: React.PropTypes.func.isRequired

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

  handleSeedToGraphToggled: ->
    arr =
      switch @props.location.type
        when "topic" then @props.graphSeeds.topics
        when "article" then @props.graphSeeds.articles
    if @props.location.entity._id in arr
      arr.splice arr.indexOf(@props.location.entity._id), 1
    else
      arr.push @props.location.entity._id
    @props.onGraphSeedsChange @props.graphSeeds

  renderSeedToGraph: ->
    return unless @props.location.entity?
    isSeeded =
      switch @props.location.type
        when "topic"
          @props.graphSeeds.topics.indexOf(@props.location.entity._id) >= 0
        when "article"
          @props.graphSeeds.articles.indexOf(@props.location.entity._id) >= 0
    iClassName =
      unless isSeeded then "fa fa-toggle-off"
      else "fa fa-toggle-on"
    <div className="pull-right" onClick={@handleSeedToGraphToggled}>
      <span className="text-muted">Graph: </span>
      <button className="btn btn-link" style={padding: 0}>
        <i className={iClassName} style={lineHeight: "inherit"} />
      </button>
    </div>

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
        <li onClick={@handleICCLicked} style={whiteSpace: "nowrap"}>
          <a href="#">{loc.ingestedCorpus}</a>
        </li>
      else
        <li className="active" style={whiteSpace: "nowrap"}>
          {loc.ingestedCorpus}
        </li>
    numLI =
      unless loc.numTopics?
        # no op
      else if loc.entity?
         <li onClick={@handleNumClicked}>
          <a href="#">{loc.numTopics} topics</a>
        </li>
      else
        <li className="active">
          {loc.numTopics} topics
        </li>
    entityLI =
      unless loc.entity?
        # no op
      else
        entityText =
          switch loc.type
            when "topic"
              loc.entity.words[0...3]
                .map (x) -> x.word
                .concat "…"
                .join ", "
            when "article"
              loc.entity.name
        <li className="active" style={whiteSpace: "nowrap"}>
          {entityText}
        </li>
    <ol className="breadcrumb">
      {@renderSeedToGraph()}
      {homeLI}
      {typeLI}
      {icLI}
      {numLI}
      {entityLI}
    </ol>
