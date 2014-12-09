# @cjsx React.DOM

BinaryPieChart = require "../../../binary-pie-chart"
React = require "react"
Tooltip = require "../../../tooltip"

{
  calls: browseArticles
  isCached: browseArticlesIsCached
} = require "../../../../async-calls/browse-articles"

module.exports = React.createClass
  displayName: "RelatedArticles"
  propTypes:
    location: React.PropTypes.shape(
      ingestedCorpus: React.PropTypes.string.isRequired
      entity: React.PropTypes.string.isRequired
    ).isRequired
    onLocationChange: React.PropTypes.func.isRequired

  getInitialState: ->
    @getDefaultState()

  getDefaultState: ->
    similarArticles: null
    loadingSimilarArticles: false

  componentWillReceiveProps: (props) ->
    @setState @getDefaultState()
    @loadSimilarArticles props if @isSimilarArticlesCached props

  isSimilarArticlesCached: (props) ->
    loc = props.location
    browseArticlesIsCached.getSimilarArticles loc.ingestedCorpus, loc.entity

  loadSimilarArticles: (props) ->
    @setState loadingSimilarArticles: true
    loc = props.location
    browseArticles.getSimilarArticles loc.ingestedCorpus, loc.entity,
      (similarArticles) =>
        @setState
          similarArticles: similarArticles
          loadingSimilarArticles: false

  handleSimilarArticleClicked: (similarArticle) ->
    @props.onLocationChange
      type: "article"
      ingestedCorpus: similarArticle.ingestedCorpus
      entity: similarArticle.articleID

  renderSimilarArticleLI: (similarArticle, i) ->
    correlation = similarArticle.correlation * 100
    correlation = correlation.toFixed 2
    pieTitle = "Correlation: #{correlation}%"
    pieChart =
      <div className="pull-right">
        <Tooltip placement="right" title={pieTitle}>
          <BinaryPieChart
            size={40}
            radius={18}
            fraction={similarArticle.correlation}
            trueColor="#777"
            falseColor="#eee"
          />
        </Tooltip>
      </div>
    <a
      className="list-group-item"
      key={i}
      href="#"
      onClick={@handleSimilarArticleClicked.bind @, similarArticle}>
      {pieChart}
      <div>{similarArticle.articleID}</div>
      <div>
        <small className="text-muted">in </small>
        {similarArticle.ingestedCorpus}
      </div>
    </a>

  renderSimilarArticlesUL: ->
    return unless @state.similarArticles? and not @state.loadingSimilarArticles
    similarArticles =
      for similarArticle, i in @state.similarArticles
        @renderSimilarArticleLI similarArticle, i
    <div className="list-group">
      {similarArticles}
    </div>

  renderLoadingIndicator: ->
    return unless @state.loadingSimilarArticles
    <div className="panel-body text-center">
      <i
        className="fa fa-circle-o-notch fa-spin"
        style={opacity: 0.5}
      />
    </div>

  renderLoadButton: ->
    return if @state.similarArticles? or @state.loadingSimilarArticles
    <div className="panel-body">
      <button
        className="col-sm-4 col-sm-offset-4 btn btn-default"
        onClick={@loadSimilarArticles.bind @, @props}>
        Load
      </button>
    </div>

  render: ->
    <div className="panel panel-default">
      <div className="panel-heading">
        <h3 className="panel-title">Related Articles</h3>
      </div>
      {@renderSimilarArticlesUL()}
      {@renderLoadingIndicator()}
      {@renderLoadButton()}
    </div>

  componentDidMount: ->
    @loadSimilarArticles @props if @isSimilarArticlesCached @props
