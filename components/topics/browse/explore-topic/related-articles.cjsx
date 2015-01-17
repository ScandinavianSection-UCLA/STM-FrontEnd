# @cjsx React.DOM

BinaryPieChart = require "../../../binary-pie-chart"
browseTopics = require("../../../../async-calls/browse-topics").calls
React = require "react"
Tooltip = require "../../../tooltip"

module.exports = React.createClass
  displayName: "RelatedArticles"
  propTypes:
    location: React.PropTypes.shape(
      ingestedCorpus: React.PropTypes.string.isRequired
      numTopics: React.PropTypes.number.isRequired
      entity: React.PropTypes.shape(
        _id: React.PropTypes.string.isRequired
        totalTokens: React.PropTypes.number.isRequired
        words: React.PropTypes.arrayOf React.PropTypes.shape(
          word: React.PropTypes.string.isRequired
          weight: React.PropTypes.number.isRequired
          count: React.PropTypes.number.isRequired
        ).isRequired
        phrases: React.PropTypes.arrayOf React.PropTypes.shape(
          phrase: React.PropTypes.string.isRequired
          weight: React.PropTypes.number.isRequired
          count: React.PropTypes.number.isRequired
        ).isRequired
      ).isRequired
    ).isRequired
    onLocationChange: React.PropTypes.func.isRequired

  getInitialState: ->
    @getDefaultState()

  getDefaultState: ->
    articles: null
    loadingArticles: false

  componentWillReceiveProps: (props) ->
    @setState @getDefaultState()
    @loadArticles props

  loadArticles: (props) ->
    @setState loadingArticles: true
    loc = props.location
    browseTopics.getArticlesForTopic loc.entity._id, (articles) =>
      @setState
        articles: articles
        loadingArticles: false

  handleArticleClicked: (article) ->
    @props.onLocationChange
      type: "article"
      ingestedCorpus: article.ingestedCorpus
      entity: article.article

  renderArticleLI: (article, i) ->
    proportion = article.proportion * 100
    proportion = proportion.toFixed 2
    pieTitle = "Proportion: #{proportion}%"
    pieChart =
      <div className="pull-right">
        <Tooltip placement="right" title={pieTitle}>
          <BinaryPieChart
            size={40}
            radius={18}
            fraction={article.proportion}
            trueColor="#777"
            falseColor="#eee"
          />
        </Tooltip>
      </div>
    <a
      className="list-group-item"
      key={i}
      href="#"
      onClick={@handleArticleClicked.bind @, article}>
      {pieChart}
      <div>{article.article.name}</div>
      <div>
        <small className="text-muted">in </small>
        {article.ingestedCorpus}
      </div>
    </a>

  renderArticlesUL: ->
    return unless @state.articles? and not @state.loadingArticles
    articles =
      @renderArticleLI article, i for article, i in @state.articles
    <div className="list-group">
      {articles}
    </div>

  renderLoadingIndicator: ->
    return unless @state.loadingArticles
    <div className="panel-body text-center">
      <i
        className="fa fa-circle-o-notch fa-spin"
        style={opacity: 0.5}
      />
    </div>

  render: ->
    <div className="panel panel-default">
      <div className="panel-heading">
        <h3 className="panel-title">Related Articles</h3>
      </div>
      {@renderArticlesUL()}
      {@renderLoadingIndicator()}
    </div>

  componentDidMount: ->
    @loadArticles @props
