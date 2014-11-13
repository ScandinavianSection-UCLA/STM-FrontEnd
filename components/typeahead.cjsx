# @cjsx React.DOM

React = require "react"

module.exports = React.createClass
  propTypes:
    value: React.PropTypes.string
    onChange: React.PropTypes.func.isRequired
    onBlur: React.PropTypes.func
    autoFocus: React.PropTypes.bool
    suggestions: React.PropTypes.arrayOf(React.PropTypes.string).isRequired

  getInitialState: ->
    @getDefaultState @props

  getDefaultProps: ->
    autoFocus: false

  componentWillReceiveProps: (newProps) ->
    if newProps.value isnt @props.value
      @setState @getDefaultState newProps

  getDefaultState: (props) ->
    selectedSuggestion:
      if @getItems(props.value).length > 0 then 0
      else null

  getItems: (value) ->
    query = ".*"
    query += "#{c}.*" for c in value ? @props.value
    regexp = new RegExp query, "ig"
    items =
      for item in @props.suggestions when item.match(regexp)?
        item
    items[...8]

  suggestionSelected: (index) ->
    @props.onChange @getItems()[index]
    @refs.input.getDOMNode().blur()

  renderDropdown: ->
    items = @getItems()
    return null if items.length is 0
    dropdownItems =
      for item, key in items
        a = <a href="#">{item}</a>
        if @state.selectedSuggestion is key
          <li
            key={key}
            className="active"
            onMouseDown={@suggestionSelected.bind @, key}>
            {a}
          </li>
        else
          <li
            key={key}
            onMouseDown={@suggestionSelected.bind @, key}>
            {a}
          </li>
    <div className="dropdown-menu" style={left: 0, right: 0, display: "block"}>
      {dropdownItems}
    </div>

  handleChanged: (event) ->
    @props.onChange event.target.value

  handleBlured: ->
    @props.onBlur?()

  handleKeyDown: (event) ->
    handled = true
    if event.keyCode is 38 # up arrow
      if @state.selectedSuggestion?
        @setState selectedSuggestion:
          (@state.selectedSuggestion - 1) %% @getItems().length
    else if event.keyCode is 40 # down arrow
      if @state.selectedSuggestion?
        @setState selectedSuggestion:
          (@state.selectedSuggestion + 1) %% @getItems().length
    else if event.keyCode is 13 # enter key
      @suggestionSelected @state.selectedSuggestion
      @refs.input.getDOMNode().blur()
    else
      handled = false
    if handled
      event.stopPropagation()

  renderInput: ->
    <input
      ref="input"
      type="text"
      className="form-control"
      value={@props.value}
      onChange={@handleChanged}
      onBlur={@handleBlured}
      onKeyDown={@handleKeyDown}
    />

  render: ->
    <div style={position: "relative"}>
      {@renderInput()}
      {@renderDropdown()}
    </div>

  componentDidMount: ->
    @refs.input.getDOMNode().focus()
    @refs.input.getDOMNode().select()
