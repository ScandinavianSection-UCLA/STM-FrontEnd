async = require "async"
asyncCaller = require "../async-caller"
dataPath = require("../constants").dataPath
db = require "../db"
fs = require "node-fs"

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

  getContent: (icName, articleID, callback) ->
    async.waterfall [
      (callback) ->
        db.IngestedCorpus.findOne name: icName, callback
      (ic, callback) ->
        fs.readFile "#{dataPath}/files/#{ic.corpus}/#{articleID}",
          encoding: "utf8", callback
    ], (err, content) ->
      return console.error err if err?
      callback content

  getRelatedInferencers: (icName, articleID, callback) ->
    async.waterfall [
      (callback) ->
        db.IngestedCorpus.findOne name: icName, callback
      (ic, callback) ->
        db.TopicsInferred.find ingestedCorpus: ic._id, callback
      (topicsInferred, callback) ->
        tiIDs = topicsInferred.map (x) -> x._id
        db.SaturationRecord.aggregate()
          .match
            topicsInferred: $in: tiIDs
            articleID: articleID
          .group
            _id: "$topicsInferred"
            topics:
              $push:
                topic: "$topic"
                proportion: "$proportion"
          .exec callback
      (results, callback) ->
        db.TopicsInferred.populate results,
          path: "_id"
          select: "inferencer"
          callback
      (results, callback) ->
        db.Inferencer.populate results,
          path: "_id.inferencer"
          select: "ingestedCorpus numTopics"
          callback
      (results, callback) ->
        db.IngestedCorpus.populate results,
          path: "_id.inferencer.ingestedCorpus"
          select: "name"
          callback
      (results, callback) ->
        db.Topic.populate results,
          path: "topics.topic"
          select: "totalTokens words phrases"
          callback
    ], (err, results) ->
      return console.error err if err?
      results = results.map (result) ->
        ingestedCorpus: result._id.inferencer.ingestedCorpus.name
        numTopics: result._id.inferencer.numTopics
        topics: result.topics.sort (a, b) -> b.proportion - a.proportion
      callback results

module.exports = asyncCaller
  mountPath: "/async-calls/browse-articles"
  calls: browseArticles
  shouldCache: true
