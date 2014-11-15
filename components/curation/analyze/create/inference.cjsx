# @cjsx React.DOM

React = require "react"

module.exports = React.createClass
  getInitialState: ->
    inferFrom: "self"

  handleInferFromChanged: (inferFrom) ->
    @setState inferFrom: inferFrom

  renderInferFromButtons: ->
    selfClass = "btn btn-default"
    anotherClass = "btn btn-default"
    switch @state.inferFrom
      when "self"
        selfClass = "btn btn-primary"
      when "another"
        anotherClass = "btn btn-primary"    
    <div className="btn-group btn-group-justified">
      <div className="btn-group">
        <button
          type="button"
          className={selfClass}
          onClick={@handleInferFromChanged.bind @, "self"}>
          Infer topics on self
        </button>
      </div>
      <div className="btn-group">
        <button
          type="button"
          className={anotherClass}
          onClick={@handleInferFromChanged.bind @, "another"}>
          Infer topics from …
        </button>
      </div>
    </div>

  render: ->
    <div className="panel panel-default">
      <div className="panel-heading">
        <h3 className="panel-title">Inference</h3>
      </div>
      <div className="panel-body">
        {@renderInferFromButtons()}
      </div>
    </div>
