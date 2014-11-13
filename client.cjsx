docReady = require "doc-ready"
Page = require "./components/page"
React = require "react"
RootView = require "root-view"

window.$ = window.jQuery = require "jquery"
Bootstrap = require "bootstrap"
dropzone = require "dropzone/downloads/dropzone.min"

docReady ->
  page =
    <Page title={process.env.PAGE_TITLE} bundle={process.env.BUNDLE_ID}>
      <RootView />
    </Page>
  React.render page, document
