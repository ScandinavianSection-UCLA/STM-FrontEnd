# @cjsx React.DOM

React = require "React"

module.exports = React.createClass
  propTypes:
    title: React.PropTypes.string
    bundle: React.PropTypes.string
  render: ->
    <html>
      <head>
        <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1"/>
        <title>{this.props.title}</title>
        <script src="/bundles/#{this.props.bundle}" />
      </head>
      <body>
        {this.props.children}
      </body>
    </html>
