# @cjsx React.DOM

bundleConstants = require "../bundle-constants"
Curation = require "../views/curation"
express = require "express"
Page = require "../views/page"
React = require "react"

router = express.Router()

router.get "/", (req, res, next) ->
  res.redirect "/curation"

router.get "/curation", (req, res, next) ->
  res.send React.renderToString(
    <Page title={bundleConstants.curation.title} bundle="curation">
      <Curation />
    </Page>
  )

module.exports = router
