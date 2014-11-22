# @cjsx React.DOM

React = require "react"
SelectIngestedCorpus = require "./existing/select-ingested-corpus"
TopicModeling = require "./existing/topic-modeling"

module.exports = React.createClass
  displayName: "Existing"
  propTypes:
    initialIngestedCorpus: React.PropTypes.string

  getInitialState: ->
    ingestedCorpus:
      if @props.initialIngestedCorpus?
        name: @props.initialIngestedCorpus
        status: "unknown"
    numTopics: null

  handleIngestedCorpusChanged: (ingestedCorpus) ->
    @setState
      ingestedCorpus: ingestedCorpus
      numTopics: null

  handleNumTopicsChanged: (numTopics) ->
    @setState numTopics: numTopics

  render: ->
    topicModeling =
      if @state.ingestedCorpus?.status is "done"
        <TopicModeling
          ingestedCorpus={@state.ingestedCorpus}
          numTopics={@state.numTopics}
          onNumTopicsChange={@handleNumTopicsChanged}
        />
    <div>
      <SelectIngestedCorpus
        ingestedCorpus={@state.ingestedCorpus}
        onIngestedCorpusChange={@handleIngestedCorpusChanged}
      />
      {topicModeling}
    </div>
