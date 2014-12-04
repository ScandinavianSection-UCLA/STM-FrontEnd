async = require "async"
asyncCaller = require "../async-caller"
db = require "../db"

browseArticles =
  getIngestedCorpora: (callback) ->
    async.waterfall [
      (callback) ->
        db.SaturationRecord
          .distinct "topicsInferred"
          .exec callback
      (topicsInferredIDs, callback) ->
        db.TopicsInferred
          .find
            _id: $in: topicsInferredIDs
            status: "done"
          .distinct "ingestedCorpus"
          .exec callback
      (icIDs, callback) ->
        db.IngestedCorpus.find _id: $in: icIDs, "name", callback
    ], (err, ics) ->
        return console.error err if err?
        icNames = ics.map (x) -> x.name
        callback icNames

  validateICName: (name, callback) ->
    @getIngestedCorpora (icNames) ->
      callback icNames.indexOf(name) >= 0

  getArticlesForIC: (name, callback) ->
    async.waterfall [
      (callback) ->
        db.IngestedCorpus.findOne name: name, callback
      (ic, callback) ->
        db.TopicsInferred.find ingestedCorpus: ic._id, callback
      (topicsInferred, callback) ->
        tiIDs = topicsInferred.map (x) -> x._id
        db.SaturationRecord
          .find topicsInferred: $in: tiIDs
          .distinct "articleID"
          .exec callback
    ], (err, articles) ->
      return console.error err if err?
      callback articles

module.exports = asyncCaller
  mountPath: "/async-calls/browse-articles"
  calls: browseArticles
  shouldCache: true
