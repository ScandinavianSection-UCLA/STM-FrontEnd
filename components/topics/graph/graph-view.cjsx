# @cjsx React.DOM

async = require "async"
deepEqual = require "deep-equal"
graphNodes = require("../../../async-calls/graph-nodes").calls
d3 = require "d3"
nextTick = require "next-tick"
React = require "react"
Tooltip = require "../../tooltip"
unique = require "array-unique"

containerHeight = 600

module.exports = React.createClass
  displayName: "GraphView"
  propTypes:
    graphSeeds: React.PropTypes.shape(
      topics: React.PropTypes.arrayOf React.PropTypes.string
      articles: React.PropTypes.arrayOf React.PropTypes.string
    ).isRequired
    containerWidth: React.PropTypes.number.isRequired

  getInitialState: ->
    force: @initializeForce()
    forceNodes: []
    forceLinks: []
    nodeBeingDragged: null

  componentWillReceiveProps: (props) ->
    if @props.containerWidth isnt props.containerWidth
      @state.force
        .size [props.containerWidth, containerHeight]
        .resume()
    unless deepEqual @props.graphSeeds, props.graphSeeds
      @handleGraphSeedsUpdated props

  initializeForce: ->
    force =
      d3.layout.force()
        .nodes []
        .links []
        .size [@props.containerWidth, containerHeight]
        .linkDistance (link) ->
          300 - 270 * link.proportion
        .linkStrength (link) ->
          Math.log(link.proportion * 9 + 1) / Math.log(10)
        .charge -30
        .alpha 1
        .start()
    force.on "start", =>
      @handleForceTicked force
    force.on "tick", =>
      @handleForceTicked force
    force.on "end", =>
      @handleForceTicked force
    force

  handleForceTicked: (force) ->
    return unless @isMounted()
    @setState
      forceNodes: force.nodes()
      forceLinks: force.links()

  handleGraphSeedsUpdated: (props) ->
    gsTopics = props.graphSeeds.topics
    gsArticles = props.graphSeeds.articles
    gsTopicIDs = gsTopics.map (x) -> x._id
    gsArticleIDs = gsArticles.map (x) -> x._id
    gsIDs = [].concat gsTopicIDs, gsArticleIDs
    forceNodeIDs = []
    forceLinks = @state.forceLinks.filter ({source, target}) ->
      result = source.value._id in gsIDs and target.value._id in gsIDs
      forceNodeIDs.push source.value._id, target.value._id if result
      result
    unique forceNodeIDs
    forceNodes = @state.forceNodes.filter (node) ->
      node.value._id in forceNodeIDs
    @state.force
      .nodes forceNodes
      .links forceLinks
      .start()

    async.auto
      topics: (callback) =>
        topicsToFetch = gsTopics.filter (x) ->
          x not in forceNodeIDs
        async.mapLimit topicsToFetch, 10,
          (topic, callback) ->
            graphNodes.expandTopicNode topic, (topics) ->
              callback null, topics
          callback
      articles: (callback) =>
        articlesToFetch = gsArticles.filter (x) ->
          x not in forceNodeIDs
        async.mapLimit articlesToFetch, 10,
          (article, callback) ->
            graphNodes.expandArticleNode article, (articles) ->
              callback null, articles
          callback
      (err, {topics: topicsFetched, articles: articlesFetched}) =>
        return console.error err if err?
        forceNodes = @state.forceNodes
        forceLinks = @state.forceLinks
        for {topic, articles} in topicsFetched
          forceTopic =
            forceNodes.filter((x) -> x.value._id is topic._id)[0]
          unless forceTopic?
            forceTopic =
              value: topic
              type: "topic"
              x: @props.containerWidth / 2 + (Math.random() - 0.5) * 100
              y: containerHeight / 2 +  + (Math.random() - 0.5) * 100
            forceNodes.push forceTopic
          for {article, proportion} in articles
            forceArticle =
              forceNodes.filter((x) -> x.value._id is article._id)[0]
            unless forceArticle?
              forceArticle =
                value: article
                type: "article"
                x: @props.containerWidth / 2 + (Math.random() - 0.5) * 100
                y: containerHeight / 2 +  + (Math.random() - 0.5) * 100
              forceNodes.push forceArticle
            forceTuple = [forceTopic, forceArticle]
            forceLink =
              forceLinks.filter(
                (x) -> x.source in forceTuple and x.target in forceTuple
              )[0]
            unless forceLink?
              forceLink =
                source: forceTopic
                target: forceArticle
              forceLinks.push forceLink
            forceLink.proportion = proportion
        for {article, topics} in articlesFetched
          forceArticle =
            forceNodes.filter((x) -> x.value._id is article._id)[0]
          unless forceArticle?
            forceArticle =
              value: article
              type: "article"
              x: @props.containerWidth / 2 + (Math.random() - 0.5) * 100
              y: containerHeight / 2 +  + (Math.random() - 0.5) * 100
            forceNodes.push forceArticle
          for {topic, proportion} in topics
            forceTopic =
              forceNodes.filter((x) -> x.value._id is topic._id)[0]
            unless forceTopic?
              forceTopic =
                value: topic
                type: "topic"
                x: @props.containerWidth / 2 + (Math.random() - 0.5) * 100
                y: containerHeight / 2 +  + (Math.random() - 0.5) * 100
              forceNodes.push forceTopic
            forceTuple = [forceArticle, forceTopic]
            forceLink =
              forceLinks.filter(
                (x) -> x.source in forceTuple and x.target in forceTuple
              )[0]
            unless forceLink?
              forceLink =
                source: forceArticle
                target: forceTopic
              forceLinks.push forceLink
            forceLink.proportion = proportion
        @state.force
          .nodes forceNodes
          .links forceLinks
          .start()

  handleNodeMouseDown: (node, event) ->
    @setState
      nodeBeingDragged:
        node: node
        mousePosition:
          x: event.clientX
          y: event.clientY
        nodePosition:
          x: node.x
          y: node.y

  handleNodeMouseMove: (event) ->
    return unless @state.nodeBeingDragged?
    nbd = @state.nodeBeingDragged
    nbd.node.x =
      nbd.nodePosition.x + event.clientX - nbd.mousePosition.x
    nbd.node.y =
      nbd.nodePosition.y + event.clientY - nbd.mousePosition.y
    nbd.node.fixed = false
    @state.force.nodes @state.forceNodes
    @state.force.tick()
    nbd.node.fixed = true
    @state.force.resume()
    event.preventDefault()

  handleNodeMouseUp: ->
    return unless @state.nodeBeingDragged?
    @state.nodeBeingDragged.node.fixed = false
    @setState nodeBeingDragged: null

  renderNode: (node, i) ->
    fill =
      switch node.type
        when "topic" then "rgb(60, 118, 61)"
        when "article" then "rgb(138, 109, 59)"
    nv = node.value
    title =
      switch node.type
        when "topic"
          <div className="text-left">
            Topic: {nv.name}
            <br />
            Inferencer: {nv.inferencer.ingestedCorpus}{" "}
            ({nv.inferencer.numTopics} topics)
          </div>
        when "article"
          <div className="text-left">
            Article: {nv.name}
            <br />
            Ingested Corpus: {nv.ingestedCorpus}
          </div>
    <Tooltip title={title} placement="right" key="node.#{i}">
      <circle
        cx={node.x}
        cy={node.y}
        r={5}
        stroke="white"
        strokeWidth={1}
        fill={fill}
        onMouseDown={@handleNodeMouseDown.bind @, node}
      />
    </Tooltip>

  renderLink: ({source, target}, i) ->
    <line
      x1={source.x}
      y1={source.y}
      x2={target.x}
      y2={target.y}
      key="link.#{i}"
      stroke="rgba(119, 119, 119, 0.5)"
      strokeWidth={1}
    />

  renderSVG: ->
    links = @state.forceLinks.map @renderLink
    nodes = @state.forceNodes.map @renderNode
    <svg width={@props.containerWidth} height={containerHeight}>
      {links}
      {nodes}
    </svg>

  render: ->
    @renderSVG()

  componentDidMount: ->
    @handleGraphSeedsUpdated @props
    window.addEventListener "mousemove", @handleNodeMouseMove
    window.addEventListener "mouseup", @handleNodeMouseUp

  componentWillUnmount: ->
    window.removeEventListener "mousemove", @handleNodeMouseMove
    window.removeEventListener "mouseup", @handleNodeMouseUp
