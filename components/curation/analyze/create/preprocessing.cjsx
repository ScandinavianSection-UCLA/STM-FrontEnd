# @cjsx React.DOM

React = require "react"

module.exports = React.createClass
  displayName: "Preprocessing"
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
    stopwords: React.PropTypes.shape(
      type: React.PropTypes.oneOf([
        "English"
        "Custom"
      ]).isRequired
      file: React.PropTypes.instanceOf window?.File
    )
    onStopwordsChange: React.PropTypes.func.isRequired

  handleRegexTypeChanged: (type) ->
    if @props.regexToken?.type isnt type
      @props.onTokenChange type: type

  handleTokenChanged: (token) ->
    @props.onTokenChange
      type: @props.regexToken?.type
      token: token

  handleStopwordsTypeChanged: (type) ->
    if @props.stopwords?.type isnt type
      @props.onStopwordsChange type: type

  handleStopwardsFileChanged: (e) ->
    @props.onStopwordsChange
      type: @props.stopwords?.type
      file: e.target.files[0]

  renderRegexTypeButtons: ->
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
        onClick={@handleRegexTypeChanged.bind @, "Latin"}>
        Latin
      </button>
      <button
        type="button"
        className={classicalChineseClass}
        onClick={@handleRegexTypeChanged.bind @, "Classical Chinese"}>
        Classical Chinese
      </button>
      <button
        type="button"
        className={customClass}
        onClick={@handleRegexTypeChanged.bind @, "Custom"}>
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

  renderStopwordsTypeButtons: ->
    englishClass = "col-sm-6 btn btn-default"
    customClass = "col-sm-6 btn btn-default"
    containerStyle =
      paddingLeft: 0
      paddingRight: 0
    switch @props.stopwords?.type ? "English"
      when "English"
        englishClass += " active"
        containerStyle.marginBottom = 0
      when "Custom"
        customClass += " active"
        containerStyle.marginBottom = 15
    <div className="btn-group col-sm-12" style={containerStyle}>
      <button
        type="button"
        className={englishClass}
        onClick={@handleStopwordsTypeChanged.bind @, "English"}>
        English
      </button>
      <button
        type="button"
        className={customClass}
        onClick={@handleStopwordsTypeChanged.bind @, "Custom"}>
        Custom
      </button>
    </div>

  renderStopwordsInput: ->
    if @props.stopwords?.type is "Custom"
      <input
        type="file"
        className="form-control"
        onChange={@handleStopwardsFileChanged}
      />

  render: ->
    <div className="panel panel-default">
      <div className="panel-heading">
        <h3 className="panel-title">Preprocessing</h3>
      </div>
      <div className="panel-body">
        <h5 style={marginTop: 0}>Regex Token</h5>
        {@renderRegexTypeButtons()}
        <div className="clearfix" />
        {@renderTokenText()}
        <h5 style={marginTop: 15}>Stopwords</h5>
        {@renderStopwordsTypeButtons()}
        <div className="clearfix" />
        {@renderStopwordsInput()}
      </div>
    </div>
