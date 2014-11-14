# @cjsx React.DOM

files = require("../../../async-calls/files").calls
React = require "react"
socket = require "../../../socket"
UploadProgress = require "./files/upload-progress"

module.exports = React.createClass
  propTypes:
    corpusName: React.PropTypes.string.isRequired
    corpusType: React.PropTypes.oneOf(["corpus", "subcorpus"]).isRequired

  getInitialState: ->
    pendingUploads: []
    numFiles: null

  componentWillReceiveProps: (newProps) ->
    @setState
      pendingUploads: []
      numFiles: null
    @updateNumFiles()

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

  renderUploads: ->
    if @state.pendingUploads.length > 0
      uploads =
        for upload, i in @state.pendingUploads
          <UploadProgress upload={upload} key={i} />
      <ul className="list-group">
        {uploads}
      </ul>

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
      {@renderUploads()}
    </div>

  newUploadStarted: (file, xhr, formData) ->
    if @isMounted()
      @setState pendingUploads: @state.pendingUploads.concat
        file: file
        bytesSent: 0
        bytesExtracted: 0
        status: "uploading"
    formData.append "corpusName", @props.corpusName
    formData.append "corpusType", @props.corpusType

  uploadProgressChanged: (file, percentDone, bytesDone) ->
    return unless @isMounted()
    upload = @state.pendingUploads.filter((x) -> x.file is file)[0]
    return unless upload?
    upload.bytesSent = bytesDone
    @setState pendingUploads: @state.pendingUploads

  handleSocketMessage: (upload) -> ({message, bytesDone}) =>
    return unless @isMounted()
    switch message
      when "progress"
        upload.bytesExtracted = bytesDone
      when "extracted"
        upload.status = "extracted"
      when "done"
        upload.status = "done"
        @updateNumFiles()
    @setState pendingUploads: @state.pendingUploads

  uploadCompleted: (file, res) ->
    return unless @isMounted()
    upload = @state.pendingUploads.filter((x) -> x.file is file)[0]
    return unless upload?
    upload.status = res.status
    switch res.status
      when "extracting"
        socket.emit "files/subscribe", res.hash
        socket.on "files/#{res.hash}", @handleSocketMessage upload
      when "done"
        @updateNumFiles()
    @setState pendingUploads: @state.pendingUploads

  registerDropzone: ->
    $(@refs.dropzone.getDOMNode()).dropzone
      url: "/files/upload"
      parallelUploads: 5
      sending: @newUploadStarted
      uploadprogress: @uploadProgressChanged
      success: @uploadCompleted
      createImageThumbnails: false
      previewsContainer: @refs.dropzonePreviews.getDOMNode()

  updateNumFiles: ->
    files.getNumFilesInCorpus @props.corpusName, @props.corpusType, (num) =>
      return unless @isMounted()
      @setState numFiles: num

  componentDidMount: ->
    @registerDropzone()
    @updateNumFiles()

  componentWillUnmount: ->
    lastChild = document.body.lastChild
    if lastChild.nodeName.toLowerCase() is "input"
      document.body.removeChild lastChild
