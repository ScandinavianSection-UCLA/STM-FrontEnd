# @cjsx React.DOM

browseArticles = require("../../../../async-calls/browse-articles").calls
React = require "react"

module.exports = React.createClass
  displayName: "ArticleContent"
  propTypes:
    location: React.PropTypes.shape(
      ingestedCorpus: React.PropTypes.string.isRequired
      entity: React.PropTypes.string.isRequired
    ).isRequired

  getInitialState: ->
    @getDefaultState()

  getDefaultState: ->
    content: null
    loadingContent: false

  componentWillReceiveProps: (props) ->
    @setState @getDefaultState()
    @loadContent props

  loadContent: (props) ->
    @setState loadingContent: true
    loc = props.location
    browseArticles.getContent loc.ingestedCorpus, loc.entity, (content) =>
      @setState
        content: content
        loadingContent: false

  renderContent: ->
    return if @state.loadingContent
    <div className="panel-body">
      {@state.content}
    </div>

  renderLoadingIndicator: ->
    return unless @state.loadingContent
    <div className="panel-body text-center">
      <i
        className="fa fa-circle-o-notch fa-spin"
        style={opacity: 0.5}
      />
    </div>

  render: ->
    <div className="panel panel-default">
      <div className="panel-heading">
        <h3 className="panel-title">Article</h3>
      </div>
      {@renderContent()}
      {@renderLoadingIndicator()}
    </div>

  componentDidMount: ->
    @loadContent @props
