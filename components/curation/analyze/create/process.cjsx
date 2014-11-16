# @cjsx React.DOM

deepEqual = require "deep-equal"
ingestedCorpusCalls = require("../../../../async-calls/ingested-corpus").calls
nextTick = require "next-tick"
React = require "react"

module.exports = React.createClass
  propTypes:
    corpus: React.PropTypes.shape(
      name: React.PropTypes.string.isRequired
      type: React.PropTypes.oneOf(["corpus", "subcorpus"]).isRequired
    ).isRequired
    inference: React.PropTypes.shape(
      inferFrom: React.PropTypes.oneOf(["self", "another"]).isRequired
      dependsOn: React.PropTypes.string
    ).isRequired
    saveAs: React.PropTypes.string
    onSaveAsChange: React.PropTypes.func.isRequired
    onProcessStart: React.PropTypes.func.isRequired

  getInitialState: ->
    @getDefaultState @props

  getDefaultState: (props) ->
    saveAs: "#{props.corpus.name} (#{props.corpus.type})"
    saveAsFocused: false
    validatingSaveAs: false

  componentWillReceiveProps: (props) ->
    unless deepEqual(
      [@props.corpus, @props.inference]
      [props.corpus, props.inference]
    )
      @setState @getDefaultState props
      nextTick => @validateSaveAs()

  validateSaveAs: ->
    @setState validatingSaveAs: true
    ingestedCorpusCalls.validate @state.saveAs, false, (result) =>
      return unless @state.validatingSaveAs
      @setState validatingSaveAs: false
      @props.onSaveAsChange @state.saveAs unless result

  handleInputFocused: ->
    @setState
      saveAsFocused: true
      validatingSaveAs: false

  handleInputBlured: ->
    @setState saveAsFocused: false
    if @props.saveAs isnt @state.saveAs
      @props.onSaveAsChange null
      nextTick => @validateSaveAs()

  handleInputChanged : (event) ->
    @setState saveAs: event.target.value

  handleKeyDown: (event) ->
    handled = true
    if event.keyCode is 13 # enter key
      @refs.input.getDOMNode().blur()
    else
      handled = false
    if handled
      event.stopPropagation()

  renderNameBox: ->
    placeholder = "Ingested Corpus" unless @state.saveAsFocused
    divClassName = "form-group"
    accessory = null
    if @state.saveAsFocused or @state.saveAs is ""
      # no op
    else if @state.validatingSaveAs
      divClassName += " has-feedback"
      accessory =
        <i
          className="form-control-feedback fa fa-circle-o-notch fa-spin"
          style={lineHeight: "34px", opacity: 0.5}
        />
    else if @props.saveAs?
      divClassName += " has-success has-feedback"
      accessory =
        <i
          className="form-control-feedback fa fa-check"
          style={lineHeight: "34px"}
        />
    else
      divClassName += " has-error has-feedback"
      accessory =
        <i
          className="form-control-feedback fa fa-times"
          style={lineHeight: "34px"}
        />
    <div className={divClassName}>
      <label className="control-label">Save as</label>
      <input
        ref="input"
        type="text"
        className="form-control"
        value={@state.saveAs}
        onChange={@handleInputChanged}
        onFocus={@handleInputFocused}
        onBlur={@handleInputBlured}
        onKeyDown={@handleKeyDown}
        placeholder={placeholder}
      />
      {accessory}
    </div>

  render: ->
    buttonClassName = "btn btn-primary btn-lg col-sm-4 col-sm-offset-4"
    button =
      if @props.saveAs?
        <button className={buttonClassName} disabled>Process</button>
      else
        <button className={buttonClassName} disabled>Process</button>
    <div className="panel panel-default">
      <div className="panel-heading">
        <h3 className="panel-title">Process</h3>
      </div>
      <div className="panel-body">
        {@renderNameBox()}
        {button}
      </div>
    </div>

  componentDidMount: ->
    @validateSaveAs()
