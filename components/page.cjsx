# @cjsx React.DOM

MainNav = require "./main-nav"
React = require "react"

module.exports = React.createClass
  displayName: "Page"
  propTypes:
    title: React.PropTypes.string
    bundle: React.PropTypes.string

  render: ->
    <html>
      <head>
        <meta
          name="viewport"
          content="width=device-width, initial-scale=1, maximum-scale=1"
        />
        <title>{@props.title}</title>
        <script src="/bundles/#{@props.bundle}" />
        <link
          rel="stylesheet"
          type="text/css"
          href="/static/bootstrap.min.css"
        />
        <link
          rel="stylesheet"
          type="text/css"
          href="/static/font-awesome/css/font-awesome.min.css"
        />
        <link rel="stylesheet" type="text/css" href="/static/page.css" />
      </head>
      <body>
        <MainNav activeView={@props.bundle} />
        {@props.children}
      </body>
    </html>
