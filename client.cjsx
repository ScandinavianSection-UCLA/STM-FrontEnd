docReady = require "doc-ready"
React = require "react"
RootView = require "root-view"
Page = require "./views/page"

docReady ->
  page =
    <Page title={process.env.PAGE_TITLE} bundle={process.env.BUNDLE_ID}>
      <RootView />
    </Page>
  React.render page, document
