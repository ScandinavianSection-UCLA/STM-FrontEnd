# @cjsx React.DOM

browseArticles = require("../../../../async-calls/browse-articles").calls
React = require "react"

module.exports = React.createClass
  displayName: "ArticleContent"
  propTypes:
    location: React.PropTypes.shape(
      ingestedCorpus: React.PropTypes.string.isRequired
      entity: React.PropTypes.shape(
        _id: React.PropTypes.string.isRequired
        name: React.PropTypes.string.isRequired
      ).isRequired
    ).isRequired
    highlightedTopic: React.PropTypes.shape
      words: React.PropTypes.arrayOf React.PropTypes.shape(
        word: React.PropTypes.string.isRequired
      ).isRequired
      phrases: React.PropTypes.arrayOf React.PropTypes.shape(
        phrase: React.PropTypes.string.isRequired
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
    browseArticles.getContent loc.entity._id, (content) =>
      @setState
        content: content
        loadingContent: false

  renderContent: ->
    return if @state.loadingContent or not @state.content?
    str = @state.content
    content =
      if @props.highlightedTopic?
        query = @props.highlightedTopic.words.map((x) -> x.word).join "|"
        regex = new RegExp query, "ig"
        marks = []
        while match = regex.exec str
          start = match.index
          end = match.index + match[0].length - 1
          continue unless start is 0 or str[start - 1].match(/\s/)?
          continue unless end is str.length - 1 or str[end + 1].match(/\s/)?
          marks.push { start, end }
        content = []
        content.push(
          <span key={0}>
            {str[0...(marks[0]?.start ? str.length)]}
          </span>
        )
        for mark, i in marks
          content.push(
            <mark className="bg-primary" style={padding: 0} key={i * 2 + 1}>
              {str[marks[i].start..marks[i].end]}
            </mark>
          )
          content.push(
            <span key={i * 2 + 2}>
              {str[(marks[i].end + 1)...(marks[i + 1]?.start ? str.length)]}
            </span>
          )
        content
      else
        str
    <div className="panel-body">
      {content}
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
