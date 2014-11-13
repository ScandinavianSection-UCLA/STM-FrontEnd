# @cjsx React.DOM

files = require("../../../async-calls/files").calls
React = require "react"
socket = require "../../../socket"

module.exports = React.createClass
  propTypes:
    corpusName: React.PropTypes.string.isRequired
    corpusType: React.PropTypes.oneOf(["corpus", "subcorpus"]).isRequired

  getInitialState: ->
    pendingUploads: []
    numFiles: null

  renderDropzone: ->
    style =
      backgroundColor: "rgba(0, 0, 0, 0.02)"
      textAlign: "center"
      color: "rgba(0, 0, 0, 0.2)"
      cursor: "pointer"
      marginBottom: 0
    <div ref="dropzone" className="panel-body lead" style={style}>
      Drop files here to upload
      <div ref="dropzonePreviews" style={display: "none"} />
    </div>

  render: ->
    title = "Add Files"
    if @state.numFiles?
      title +=
        if @state.numFiles is 0 then " (empty #{@props.corpusType})"
        else if @state.numFiles is 1 then " (1 file in #{@props.corpusType})"
        else " (#{@state.numFiles} files in #{@props.corpusType})"
    <div className="panel panel-default">
      <div className="panel-heading">
        <h3 className="panel-title">{title}</h3>
      </div>
      {@renderDropzone()}
    </div>

  newUploadStarted: (file, xhr, formData) ->
    @setState pendingUploads: @state.pendingUploads.concat
      file: file
      corpusName: @props.corpusName
      corpusType: @props.corpusType
      bytesSent: 0
      bytesExtracted: 0
      status: "uploading"

  uploadProgressChanged: (file, percentDone, bytesDone) ->
    upload = @state.pendingUploads.filter((x) -> x.file is file)[0]
    return unless upload?
    upload.bytesSent = bytesDone
    @setState pendingUploads: @state.pendingUploads

  handleSocketMessage: (upload) -> (message, result) ->
    switch message
      when "progress"
        upload.bytesExtracted = result.bytesDone
      when "extracted"
        upload.status = "extracted"
      when "done"
        upload.status = "done"
        @updateNumFiles()
    @setState pendingUploads: @state.pendingUploads

  uploadCompleted: (file, res) ->
    upload = @state.pendingUploads.filter((x) -> x.file is file)[0]
    return unless upload?
    upload.status = res.status
    switch res.status
      when "extracting"
        socket.emit "files/subscribe", res.hash, @handleSocketMessage upload
      when "done"
        @updateNumFiles()
    @setState pendingUploads: @state.pendingUploads

  registerDropzone: ->
    $(@refs.dropzone.getDOMNode()).dropzone
      url: "/files/upload"
      parallelUploads: 5
      sending: @newUploadStarted
      uploadProgress: @uploadProgressChanged
      success: @uploadCompleted
      createImageThumbnails: false
      previewsContainer: @refs.dropzonePreviews.getDOMNode()

  updateNumFiles: ->
    files.getNumFilesInCorpus @props.corpusName, @props.corpusType, (num) =>
      @setState numFiles: num

  componentDidMount: ->
    @registerDropzone()
    @updateNumFiles()

  componentWillUnmount: ->
    lastChild = document.body.lastChild
    if lastChild.nodeName.toLowerCase() is "input"
      document.body.removeChild lastChild
