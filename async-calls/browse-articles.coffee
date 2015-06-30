async = require "async"
asyncCaller = require "../async-caller"
chunk = require "chunk"
dataPath = require("../constants").dataPath
db = require "../db"
hashCode = require "../hash-code"
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
          .distinct "article"
          .exec callback
      (articleIDs, callback) ->
        db.Article.find _id: $in: articleIDs, callback
    ], (err, articles) ->
      return console.error err if err?
      articles = articles.map (x) ->
        _id: x._id
        name: x.name
      callback articles

  getContent: (article, callback) ->
    async.waterfall [
      (callback) ->
        db.Article
          .findById article
          .populate "ingestedCorpus"
          .exec callback
      (article, callback) ->
        path = [
          dataPath
          "files"
          article.ingestedCorpus.corpus
          article.name
        ].join "/"
        fs.readFile path, encoding: "utf8", callback
    ], (err, content) ->
      return console.error err if err?
      callback content

  getRelatedInferencers: (article, callback) ->
    async.waterfall [
      (callback) ->
        db.Article.findById article, callback
      (article, callback) ->
        db.TopicsInferred.find ingestedCorpus: article.ingestedCorpus,
          (err, topicsInferred) ->
            callback err, article, topicsInferred
      (article, topicsInferred, callback) ->
        tiIDs = topicsInferred.map (x) -> x._id
        db.SaturationRecord.aggregate()
          .match
            topicsInferred: $in: tiIDs
            article: article._id
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
          select: "name totalTokens words phrases"
          callback
    ], (err, results) ->
      return console.error err if err?
      results = results.map (result) ->
        ingestedCorpus: result._id.inferencer.ingestedCorpus.name
        numTopics: result._id.inferencer.numTopics
        topics: result.topics
          .filter (x) -> not x.hidden
          .sort (a, b) -> b.proportion - a.proportion
      callback results

  getSimilarArticles: (article, callback) ->
    async.auto
      article: (callback) ->
        db.Article.findById article, callback
      thisTopicsInferred: ["article", (callback, {article}) ->
        db.TopicsInferred.find ingestedCorpus: article.ingestedCorpus, callback
      ]
      topicsInferred: ["thisTopicsInferred", (callback, {thisTopicsInferred}) ->
        inferencerIDs = thisTopicsInferred.map (x) -> x.inferencer
        db.TopicsInferred.find
          inferencer: $in: inferencerIDs
          status: "done"
          callback
      ]
      μs: ["topicsInferred", (callback, {topicsInferred}) ->
        tiIDs = topicsInferred.map (x) -> x._id
        db.SaturationRecord.aggregate()
          .match
            topicsInferred: $in: tiIDs
          .group
            _id: "$article"
            μ: $avg: "$proportion"
          .exec callback
      ]
      thisσEs: ["article", "μs", (callback, {article, μs}) ->
        thisμ = μs.filter((x) -> x._id.equals article._id)[0].μ
        db.SaturationRecord.aggregate()
          .match
            article: article._id
          .project
            _id: 0
            topic: 1
            σE: $subtract: ["$proportion", $literal: thisμ]
          .exec callback
      ]
      dist: ["thisσEs", "μs", (callback, {thisσEs, μs}) ->
        thisσEsCondObj = do ->
          thisσEs = thisσEs.sort (a, b) ->
            if a.topic < b.topic then -1 else 1
          makeBST = (low = 0, high = thisσEs.length - 1) ->
            if high is low
              $literal: thisσEs[low].σE
            else if high is low + 1
              $cond: [
                { $eq: ["$topic", $literal: thisσEs[low].topic] }
                { $literal: thisσEs[low].σE }
                { $literal: thisσEs[high].σE }
              ]
            else
              mid = Math.floor (high + low) / 2
              $cond: [
                { $eq: ["$topic", $literal: thisσEs[mid].topic] }
                { $literal: thisσEs[mid].σE }
                $cond: [
                  { $lt: ["$topic", $literal: thisσEs[mid].topic] }
                  makeBST low, mid - 1
                  makeBST mid + 1, high
                ]
              ]
          makeBST()
        μsChunks = chunk μs, 10000
        async.mapLimit(
          μsChunks
          4
          (μsChunk, callback) ->
            μsCondObj = do ->
              μsChunk = μsChunk.sort (a, b) ->
                if a._id < b._id then -1 else 1
              makeBST = (low = 0, high = μsChunk.length - 1) ->
                if high is low
                  $literal: μsChunk[low].μ
                else if high is low + 1
                  $cond: [
                    { $eq: ["$article", $literal: μsChunk[low]._id] }
                    { $literal: μsChunk[low].μ }
                    { $literal: μsChunk[high].μ }
                  ]
                else
                  mid = Math.floor (high + low) / 2
                  $cond: [
                    { $eq: ["$article", $literal: μsChunk[mid]._id] }
                    { $literal: μsChunk[mid].μ }
                    $cond: [
                      { $lt: ["$article", $literal: μsChunk[mid]._id] }
                      makeBST low, mid - 1
                      makeBST mid + 1, high
                    ]
                  ]
              makeBST()
            db.SaturationRecord.aggregate()
              .match
                article: $in: μsChunk.map (x) -> x._id
              .project
                article: 1
                topic: 1
                proportion: 1
                μ: μsCondObj
              .project
                article: 1
                topic: 1
                σE: $subtract: ["$proportion", "$μ"]
                thisσE: thisσEsCondObj
              .project
                article: 1
                cov: $multiply: ["$σE", "$thisσE"]
                σ2: $multiply: ["$σE", "$σE"]
              .group
                _id: "$article"
                cov: $avg: "$cov"
                σ2: $avg: "$σ2"
              .exec callback
          (err, distChunks) ->
            callback err, [].concat distChunks...
        )
      ]
      (err, {dist, article}) ->
        return console.error err if err?
        thisσ = dist.filter((x) -> x._id.equals article._id)[0]
        dist = dist.map (x) ->
            article: x._id
            corr: x.cov / (Math.sqrt(x.σ2) * Math.sqrt(thisσ.σ2))
        dist = dist.filter (x) -> x.corr >= 0
        dist = dist.sort (a, b) -> b.corr - a.corr
        async.waterfall [
          (callback) ->
            db.Article.populate dist[1...11], "article", callback
          (dist, callback) ->
            db.IngestedCorpus.populate dist, "article.ingestedCorpus", callback
        ], (err, dist) ->
          return console.error err if err?
          similarArticles = dist.map (x) ->
            article:
              _id: x.article._id
              name: x.article.name
            ingestedCorpus: x.article.ingestedCorpus.name
            correlation: x.corr
          callback similarArticles

module.exports = asyncCaller
  mountPath: "/async-calls/browse-articles"
  calls: browseArticles
  shouldCache: true
