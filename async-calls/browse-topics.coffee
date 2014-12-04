async = require "async"
asyncCaller = require "../async-caller"
db = require "../db"
extend = require "extend"

browseTopics =
  getIngestedCorpora: (callback) ->
    async.waterfall [
      (callback) ->
        db.Inferencer.distinct "ingestedCorpus", callback
      (inferencers, callback) ->
        db.IngestedCorpus.distinct "name", _id: $in: inferencers, callback
    ], (err, names) ->
      return console.error err if err?
      callback names

  validateICName: (name, callback) ->
    @getIngestedCorpora (names) ->
      callback name in names

  getNumTopicsForIC: (name, callback) ->
    async.waterfall [
      (callback) ->
        db.IngestedCorpus.findOne name: name, callback
      (ic, callback) ->
        db.Inferencer.distinct "numTopics", ingestedCorpus: ic._id, callback
    ], (err, numTopics) ->
      return console.error err if err?
      callback numTopics

  validateNumTopicsForIC: (name, numTopic, callback) ->
    @getNumTopicsForIC name, (numTopics) ->
      callback numTopic in numTopics

  getTopicsForIC: (name, numTopics, callback) ->
    async.waterfall [
      (callback) ->
        db.IngestedCorpus.findOne name: name, callback
      (ic, callback) ->
        db.Inferencer.findOne
          ingestedCorpus: ic._id
          numTopics: numTopics
          callback
      (inferencer, callback) ->
        db.Topic
          .find inferencer: inferencer._id, "totalTokens words phrases"
          .sort "-totalTokens"
          .exec callback
    ], (err, topics) ->
      return console.error err if err?
      callback topics

  getArticlesForTopic: (topic, callback) ->
    async.waterfall [
      (callback) ->
        db.SaturationRecord
          .find topic: topic, "topicsInferred articleID proportion"
          .sort "-proportion"
          .limit 20
          .populate "topicsInferred", "ingestedCorpus"
          .exec callback
      (saturationRecords, callback) ->
        db.IngestedCorpus.populate saturationRecords,
          path: "topicsInferred.ingestedCorpus"
          select: "name"
          callback
    ], (err, saturationRecords) ->
      return console.error err if err?
      articles = saturationRecords.map (x) ->
        ingestedCorpus: x.topicsInferred.ingestedCorpus.name
        articleID: x.articleID
        proportion: x.proportion
      callback articles

  getSimilarTopics: (topic, callback) ->
    async.auto
      thisTopic: (callback) ->
        db.Topic.findById topic, "inferencer", callback
      topics: ["thisTopic", (callback, {thisTopic}) ->
        db.Topic.find
          inferencer: thisTopic.inferencer
          "totalTokens words phrases"
          callback
      ]
      thisSats: (callback) ->
        thisSats = {}
        db.SaturationRecord
          .find
            topic: topic
            "topicsInferred articleID proportion"
          .stream()
            .on "data", (doc) ->
              thisSats[doc.topicsInferred] ?= {}
              thisSats[doc.topicsInferred][doc.articleID] = doc.proportion
            .on "error", console.error
            .on "close", ->
              callback null, thisSats
      dist: ["topics", "thisSats", (callback, {topics, thisSats}) ->
        jointDist = {}
        marginalDist = {}
        db.SaturationRecord
          .find
            topic: $in: topics.map (x) -> x._id
          .stream()
            .on "data", (doc) ->
              jointDist[doc.topic] ?= 0
              jointDist[doc.topic] +=
                doc.proportion * thisSats[doc.topicsInferred][doc.articleID]
              marginalDist[doc.topic] ?= 0
              marginalDist[doc.topic] += doc.proportion
            .on "error", console.error
            .on "close", ->
              callback null, { jointDist, marginalDist }
      ]
      (err, {dist: {jointDist, marginalDist}, topics}) ->
        return console.error err if err?
        similarTopics =
          for t in topics when (
            t._id.toString() isnt topic
          )
            denom = marginalDist[t._id] * marginalDist[topic]
            similarityScore = jointDist[t._id] / denom
            extend true, t.toObject(), { similarityScore }
        similarTopics.sort (a, b) -> b.similarityScore - a.similarityScore
        callback similarTopics

  getRelatedICs: (topic, callback) ->
    async.waterfall [
      (callback) ->
        db.Topic.findById topic, "inferencer", callback
      (topic, callback) ->
        db.TopicsInferred
          .find
            inferencer: topic.inferencer
            status: "done"
            "ingestedCorpus"
          .populate "ingestedCorpus"
          .exec callback
    ], (err, topicsInferred) ->
      return console.error err if err?
      relatedICs =
        x.ingestedCorpus for x in topicsInferred
      relatedICs.sort (a, b) -> a.name.localeCompare b.name
      callback relatedICs

module.exports = asyncCaller
  mountPath: "/async-calls/browse-topics"
  calls: browseTopics
  shouldCache: true
