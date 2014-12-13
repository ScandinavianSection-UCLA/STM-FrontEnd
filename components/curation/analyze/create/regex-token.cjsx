# @cjsx React.DOM

React = require "react"

module.exports = React.createClass
  displayName: "RegexToken"
  propTypes:
    regexToken: React.PropTypes.shape(
      type: React.PropTypes.oneOf([
        "Latin"
        "Classical Chinese"
        "Custom"
      ]).isRequired
      token: React.PropTypes.string
    )
    onTokenChange: React.PropTypes.func.isRequired

  handleTypeChanged: (type) ->
    if @props.regexToken?.type isnt type
      @props.onTokenChange type: type

  handleTokenChanged: (token) ->
    @props.onTokenChange
      type: type
      token: token

  renderTypeButtons: ->
    latinClass = "col-sm-4 btn btn-default"
    classicalChineseClass = "col-sm-4 btn btn-default"
    customClass = "col-sm-4 btn btn-default"
    containerStyle =
      paddingLeft: 0
      paddingRight: 0
      marginBottom: 15
    switch @props.regexToken?.type ? "Latin"
      when "Latin"
        latinClass += " active"
      when "Classical Chinese"
        classicalChineseClass += " active"
      when "Custom"
        customClass += " active"
    <div className="btn-group col-sm-12" style={containerStyle}>
      <button
        type="button"
        className={latinClass}
        onClick={@handleTypeChanged.bind @, "Latin"}>
        Latin
      </button>
      <button
        type="button"
        className={classicalChineseClass}
        onClick={@handleTypeChanged.bind @, "Classical Chinese"}>
        Classical Chinese
      </button>
      <button
        type="button"
        className={customClass}
        onClick={@handleTypeChanged.bind @, "Custom"}>
        Custom
      </button>
    </div>

  renderTokenText: ->
    if @props.regexToken?.type is "Custom"
      <div className="form-group" style={marginBottom: 0}>
        <input
          type="text"
          className="form-control"
          value={@props.regexToken?.token ? ""}
          onChange={@handleTokenChanged}
          placeholder="Regex Token"
        />
      </div>
    else
      text =
        switch @props.regexToken?.type ? "Latin"
          when "Latin" then "\\p{L}[\\p{L}\\p{P}]*\\p{L}"
          when "Classical Chinese" then "[\\p{L}\\p{M}]"
      <div className="form-group" style={marginBottom: 0}>
        <input
          type="text"
          className="form-control"
          value={text}
          readOnly
        />
      </div>

  render: ->
    <div className="panel panel-default">
      <div className="panel-heading">
        <h3 className="panel-title">Regex Token (used to split terms)</h3>
      </div>
      <div className="panel-body">
        {@renderTypeButtons()}
        <div className="clearfix" />
        {@renderTokenText()}
      </div>
    </div>
