# @cjsx React.DOM

browseArticles = require("../../../async-calls/browse-articles").calls
escapeStringRegexp = require "escape-string-regexp"
React = require "react"

module.exports = React.createClass
  displayName: "ExploreIngestedCorpus"
  propTypes:
    location: React.PropTypes.shape(
      ingestedCorpus: React.PropTypes.string.isRequired
    ).isRequired
    onLocationChange: React.PropTypes.func.isRequired

  getInitialState: ->
    @getDefaultState()

  getDefaultState: ->
    articles: null
    loadingArticles: false
    filterQuery: ""

  componentWillReceiveProps: (props) ->
    @setState @getDefaultState()
    @loadArticles props

  loadArticles: (props) ->
    @setState loadingArticles: true
    browseArticles.getArticlesForIC props.location.ingestedCorpus,
      (articles) =>
        @setState
          articles: articles
          loadingArticles: false

  filteredArticles: ->
    return unless @state.articles?
    query = ".*"
    query += "#{escapeStringRegexp c}.*" for c in @state.filterQuery
    regexp = new RegExp query, "ig"
    item for item in @state.articles when item.match(regexp)?

  renderArticleLI: (article, i) ->
    <a
      className="list-group-item"
      key={i}
      href="#">
      {article}
    </a>

  renderArticlesUL: ->
    return if @state.loadingArticles or not @filteredArticles()?
    if @filteredArticles().length > 0
      articles =
        @renderArticleLI article, i for article, i in @filteredArticles()[0..10]
      <div className="list-group">
        {articles}
      </div>
    else
      <div className="panel-body text-center text-muted">
        No articles match filter
      </div>

  renderLoadingIndicator: ->
    return unless @state.loadingArticles
    <div className="panel-body text-center">
      <i
        className="fa fa-circle-o-notch fa-spin"
        style={opacity: 0.5}
      />
    </div>

  renderFooter: ->
    return if @state.loadingArticles or not @filteredArticles()?
    return unless @filteredArticles().length > 10
    more = @filteredArticles().length - 10
    subject = if more is 1 then "article" else "articles"
    <div className="panel-footer text-muted">
      {more} more {subject}…
    </div>

  handleFilterQueryChanged: (event) ->
    @setState filterQuery: event.target.value

  render: ->
    ic = @props.location.ingestedCorpus
    <div className="col-sm-6 col-sm-offset-3">
      <div className="panel panel-default">
        <div className="panel-heading">
          <h3 className="panel-title" style={marginBottom: 10}>
            Articles in {ic}
          </h3>
          <div className="input-group">
            <span className="input-group-addon">
              <i className="fa fa-search" />
            </span>
            <input
              type="text"
              className="form-control"
              placeholder="Filter"
              value={@state.filterQuery}
              onChange={@handleFilterQueryChanged}
            />
          </div>
        </div>
        {@renderArticlesUL()}
        {@renderLoadingIndicator()}
        {@renderFooter()}
      </div>
    </div>

  componentDidMount: ->
    @loadArticles @props
