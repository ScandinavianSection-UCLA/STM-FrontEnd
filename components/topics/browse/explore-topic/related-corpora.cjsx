# @cjsx React.DOM

browseTopics = require("../../../../async-calls/browse-topics").calls
React = require "react"

module.exports = React.createClass
  displayName: "ExploreInferencer"
  propTypes:
    location: React.PropTypes.shape(
      entity: React.PropTypes.shape(
        _id: React.PropTypes.string.isRequired
      ).isRequired
    ).isRequired
    onLocationChange: React.PropTypes.func.isRequired

  getInitialState: ->
    @getDefaultState()

  getDefaultState: ->
    relatedICs: null
    loadingRelatedICs: false

  componentWillReceiveProps: (props) ->
    @setState @getDefaultState()
    @loadRelatedICs props

  loadRelatedICs: (props) ->
    @setState loadingRelatedICs: true
    loc = props.location
    browseTopics.getRelatedICs loc.entity._id, (relatedICs) =>
      @setState
        relatedICs: relatedICs
        loadingRelatedICs: false

  handleRelatedICClicked: (relatedIC) ->
    @props.onLocationChange
      type: "article"
      ingestedCorpus: relatedIC.name

  renderRelatedICsLI: (relatedIC, i) ->
    <a
      className="list-group-item"
      key={i}
      href="#"
      onClick={@handleRelatedICClicked.bind @, relatedIC}>
      {relatedIC.name}
    </a>

  renderRelatedICsUL: ->
    return unless @state.relatedICs? and not @state.loadingRelatedICs
    relatedICs =
      @renderRelatedICsLI relatedIC, i for relatedIC, i in @state.relatedICs
    <div className="list-group">
      {relatedICs}
    </div>

  renderLoadingIndicator: ->
    return unless @state.loadingRelatedICs
    <div className="panel-body text-center">
      <i
        className="fa fa-circle-o-notch fa-spin"
        style={opacity: 0.5}
      />
    </div>

  render: ->
    <div className="panel panel-default">
      <div className="panel-heading">
        <h3 className="panel-title">Inferred on Corpora</h3>
      </div>
      {@renderRelatedICsUL()}
      {@renderLoadingIndicator()}
    </div>

  componentDidMount: ->
    @loadRelatedICs @props
