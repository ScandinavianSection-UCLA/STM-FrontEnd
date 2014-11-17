# @cjsx React.DOM

React = require "react"

module.exports = React.createClass
  displayName: "UploadProgress"
  propTypes:
    upload: React.PropTypes.shape(
      file: React.PropTypes.object.isRequired
      bytesSent: React.PropTypes.number.isRequired
      bytesExtracted: React.PropTypes.number.isRequired
      status: React.PropTypes.string.isRequired
    ).isRequired

  getFriendlyFileSize: ->
    size = @props.upload.file.size
    suffixes = ["KiB", "MiB", "GiB", "TiB"]
    order = Math.min parseInt(Math.log(size + 1) / Math.log(1024)), 4
    if order is 0
      "#{size} bytes"
    else
      friendlySize = size / Math.pow(1024, order)
      "#{friendlySize.toFixed 2} #{suffixes[order - 1]}"

  renderProgressBar: ->
    containerClassName = "progress"
    progressClassName = "progress-bar"
    switch @props.upload.status
      when "extracted"
        containerClassName += " progress-striped active"
      when "done"
        progressClassName += " progress-bar-success"
      when "failure"
        progressClassName += " progress-bar-danger"
    extractPercent =
      @props.upload.bytesExtracted / @props.upload.file.size * 100
    sentPercent = @props.upload.bytesSent / @props.upload.file.size * 100
    secondBar =
      if @props.upload.status in ["extracting", "extracted"]
        <div
          className="progress-bar progress-bar-info"
          style={width: "#{extractPercent}%", position: "absolute"}
        />
    <div
      className={containerClassName}
      style={marginBottom: "4px", position: "relative"}>
      <div
        className={progressClassName}
        style={width: "#{sentPercent}%", position: "absolute"}
      />
      {secondBar}
    </div>

  render: ->
    <li className="list-group-item">
      <p className="pull-left">
        <small>Uploading </small>
        <strong>{@props.upload.file.name}</strong>
      </p>
      <p className="pull-right">
        {@getFriendlyFileSize()}
      </p>
      <div className="clearfix" />
      {@renderProgressBar()}
    </li>
