async = require "async"
asyncCaller = require "../async-caller"
chunk = require "chunk"
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
          .find topic: topic, "topicsInferred article proportion"
          .sort "-proportion"
          .limit 20
          .populate "topicsInferred", "ingestedCorpus"
          .populate "article"
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
        article:
          _id: x.article._id
          name: x.article.name
        proportion: x.proportion
      callback articles

  getSimilarTopics: (topic, callback) ->
    async.auto
      thisTopic: (callback) ->
        db.Topic.findById topic, callback
      ingestedCorporaIDs: ["thisTopic", (callback, {thisTopic}) ->
        db.TopicsInferred
          .find inferencer: thisTopic.inferencer
          .distinct "ingestedCorpus"
          .exec callback
      ]
      tiIDs:["ingestedCorporaIDs", (callback, {ingestedCorporaIDs}) ->
        db.TopicsInferred
          .find ingestedCorpus: $in: ingestedCorporaIDs
          .distinct "_id"
          .exec callback
      ]
      μs: ["tiIDs", (callback, {tiIDs}) ->
        db.SaturationRecord.aggregate()
          .match
            topicsInferred: $in: tiIDs
          .group
            _id: "$topic"
            μ: $avg: "$proportion"
          .exec callback
      ]
      thisσEs: ["thisTopic", "μs", (callback, {thisTopic, μs}) ->
        thisμ = μs.filter((x) -> x._id.equals thisTopic._id)[0].μ
        db.SaturationRecord.aggregate()
          .match
            topic: thisTopic._id
          .project
            _id: 0
            article: 1
            σE: $subtract: ["$proportion", $literal: thisμ]
          .exec callback
      ]
      aggCols: ["thisσEs", "μs", (callback, {thisσEs, μs}) ->
        μsCondObj = do ->
          μs = μs.sort (a, b) ->
            if a._id < b._id then -1 else 1
          makeBST = (low = 0, high = μs.length - 1) ->
            if high is low
              $literal: μs[low].μ
            else if high is low + 1
              $cond: [
                { $eq: ["$topic", $literal: μs[low]._id] }
                { $literal: μs[low].μ }
                { $literal: μs[high].μ }
              ]
            else
              mid = Math.floor (high + low) / 2
              $cond: [
                { $eq: ["$topic", $literal: μs[mid]._id] }
                { $literal: μs[mid].μ }
                $cond: [
                  { $lt: ["$topic", $literal: μs[mid]._id] }
                  makeBST low, mid - 1
                  makeBST mid + 1, high
                ]
              ]
          makeBST()
        thisσEsChunks = chunk thisσEs, 20000
        async.mapLimit(
          thisσEsChunks
          4
          (thisσEsChunk, callback) ->
            thisσEsCondObj = do ->
              thisσEsChunk = thisσEsChunk.sort (a, b) ->
                if a.article < b.article then -1 else 1
              makeBST = (low = 0, high = thisσEsChunk.length - 1) ->
                if high is low
                  $literal: thisσEsChunk[low].σE
                else if high is low + 1
                  $cond: [
                    { $eq: ["$article", $literal: thisσEsChunk[low].article] }
                    { $literal: thisσEsChunk[low].σE }
                    { $literal: thisσEsChunk[high].σE }
                  ]
                else
                  mid = Math.floor (high + low) / 2
                  $cond: [
                    { $eq: ["$article", $literal: thisσEsChunk[mid].article] }
                    { $literal: thisσEsChunk[mid].σE }
                    $cond: [
                      { $lt: ["$article", $literal: thisσEsChunk[mid].article] }
                      makeBST low, mid - 1
                      makeBST mid + 1, high
                    ]
                  ]
              makeBST()
            aggCol = db.createTemporaryCollection()
            db.SaturationRecord.aggregate()
              .match
                topic: $in: μs.map (x) -> x._id
                article: $in: thisσEsChunk.map (x) -> x.article
              .project
                article: 1
                topic: 1
                proportion: 1
                μ: μsCondObj
                thisσE: thisσEsCondObj
              .match
                thisσE: $ne: null
              .project
                article: 1
                topic: 1
                σE: $subtract: ["$proportion", "$μ"]
                thisσE: 1
              .project
                topic: 1
                cov: $multiply: ["$σE", "$thisσE"]
                σ2: $multiply: ["$σE", "$σE"]
              .group
                _id: "$topic"
                cov: $sum: "$cov"
                σ2: $sum: "$σ2"
                count: $sum: 1
              .project
                _id: 0
                topic: "$_id"
                cov: 1
                σ2: 1
                count: 1
              .append
                $out: aggCol.collection.name
              .exec (err) ->
                callback err, aggCol
          callback
        )
      ]
      aggCol: ["aggCols", (callback, {aggCols}) ->
        aggCol = db.createTemporaryCollection()
        async.each aggCols,
          (x, callback) ->
            db.eval(
              "db.#{x.collection.name}.copyTo(\"#{aggCol.collection.name}\")"
              callback
            )
          (err) ->
            x.collection.drop() for x in aggCols
            callback err, aggCol
      ]
      dist: ["aggCol", (callback, {aggCol}) ->
        aggCol.aggregate()
          .group
            _id: "$topic"
            cov: $sum: "$cov"
            σ2: $sum: "$σ2"
            count: $sum: "$count"
          .project
            cov: $divide: ["$cov", "$count"]
            σ2: $divide: ["$σ2", "$count"]
          .exec callback
      ]
      (err, {dist, thisTopic, aggCol}) ->
        return console.error err if err?
        aggCol.collection.drop()
        thisσ = dist.filter((x) -> x._id.equals thisTopic._id)[0]
        dist = dist.map (x) ->
          topic: x._id
          corr: x.cov / (Math.sqrt(x.σ2) * Math.sqrt(thisσ.σ2))
        dist = dist.filter (x) -> x.corr > 0
        dist = dist.sort (a, b) -> b.corr - a.corr
        async.waterfall [
          (callback) ->
            db.Topic.populate dist[1...11], "topic", callback
          (dist, callback) ->
            db.Inferencer.populate dist, "topic.inferencer", callback
          (dist, callback) ->
            db.IngestedCorpus.populate dist, "topic.inferencer.ingestedCorpus",
              callback
        ], (err, dist) ->
          return console.error err if err?
          similarTopics = dist.map (x) ->
            topic:
              _id: x.topic._id
              totalTokens: x.topic.totalTokens
              words: x.topic.words
              phrases: x.topic.phrases
            ingestedCorpus: x.topic.inferencer.ingestedCorpus.name
            numTopics: x.topic.inferencer.numTopics
            correlation: x.corr
          callback similarTopics

  getRelatedICs: (topic, callback) ->
    async.waterfall [
      (callback) ->
        db.Topic.findById topic, "inferencer", callback
      (topic, callback) ->
        db.TopicsInferred .find
          inferencer: topic.inferencer
          status: "done"
          callback
      (topicsInferred, callback) ->
        tiIDs = topicsInferred.map (x) -> x._id
        db.SaturationRecord
          .find topicsInferred: $in: tiIDs
          .distinct "topicsInferred"
          .exec callback
      (filteredTIIDs, callback) ->
        db.TopicsInferred
          .find _id: $in: filteredTIIDs, "ingestedCorpus"
          .populate "ingestedCorpus"
          .exec callback
    ], (err, filteredTopicsInferred) ->
      return console.error err if err?
      relatedICs =
        x.ingestedCorpus for x in filteredTopicsInferred
      relatedICs.sort (a, b) -> a.name.localeCompare b.name
      callback relatedICs

module.exports = asyncCaller
  mountPath: "/async-calls/browse-topics"
  calls: browseTopics
  shouldCache: true
