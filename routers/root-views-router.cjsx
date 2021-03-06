# @cjsx React.DOM

bundleConstants = require("../constants").bundles
Curation = require "../components/curation"
express = require "express"
Page = require "../components/page"
React = require "react"
Topics = require "../components/topics"

router = express.Router()

router.get "/", (req, res, next) ->
  res.redirect "/curation"

router.get "/curation", (req, res, next) ->
  res.send React.renderToString(
    <Page title={bundleConstants.curation.title} bundle="curation">
      <Curation />
    </Page>
  )

router.get "/topics", (req, res, next) ->
  res.send React.renderToString(
    <Page title={bundleConstants.topics.title} bundle="topics">
      <Topics />
    </Page>
  )

module.exports = router
