aliasify = require "aliasify"
browserify = require "browserify"
bundleConstants = require("../constants").bundles
coffeeReactify = require "coffee-reactify"
envify = require "envify/custom"
express = require "express"
StreamCache = require "stream-cache"

bundles = {}

getBundle = (bundle) ->
  return bundles[bundle] if bundles[bundle]?
  b = browserify
    entries: ["./client"]
    extensions: [".cjsx", ".coffee"]
  b.transform coffeeReactify
  b.transform aliasify.configure
    aliases:
      "root-view": "../components/#{bundle}"
      "../db": "nop"
      "fs-extra": "fs"
    configDir: __dirname
    appliesTo:
      includeExtensions: [".cjsx", ".coffee"]
  b.transform envify
    BUNDLE_ID: bundle
    PAGE_TITLE: bundleConstants[bundle].title
  cache = new StreamCache()
  b.bundle().pipe cache
  return bundles[bundle] = cache

router = express.Router()

router.get "/:bundle", (req, res, next) ->
  getBundle(req.params.bundle).pipe res

module.exports = router
