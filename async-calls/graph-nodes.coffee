async = require "async"
asyncCaller = require "../async-caller"
db = require "../db"

graphNodes =
  expandTopicNode: (topic, callback) ->
    async.parallel [
      (callback) ->
        async.waterfall [
          (callback) ->
            db.Topic
              .findById topic, "name hidden words inferencer"
              .populate "inferencer", "ingestedCorpus"
              .exec callback
          (topic, callback) ->
            db.IngestedCorpus.populate topic,
              path: "inferencer.ingestedCorpus"
              select: "name"
              callback
        ], callback
      (callback) ->
        async.waterfall [
          (callback) ->
            db.SaturationRecord
              .find
                topic: topic
                proportion: $gt: 0.1
                "topicsInferred article proportion"
              .sort "-proportion"
              .populate "topicsInferred", "ingestedCorpus"
              .populate "article"
              .exec callback
          (saturationRecords, callback) ->
            db.IngestedCorpus.populate saturationRecords,
              path: "topicsInferred.ingestedCorpus"
              select: "name"
              callback
        ], callback
    ], (err, [topic, saturationRecords]) ->
      return console.error err if err?
      topic =
        _id: topic._id
        name:
          topic.name ?
          topic.words[0...3]
            .map (x) -> x.word
            .concat "…"
            .join ", "
        inferencer:
          ingestedCorpus: topic.inferencer.ingestedCorpus.name
          numTopics: topic.inferencer.numTopics
      articles = saturationRecords.map (x) ->
        article:
          _id: x.article._id
          name: x.article.name
          ingestedCorpus: x.topicsInferred.ingestedCorpus.name
        proportion: x.proportion
      callback { topic, articles }

  expandArticleNode: (article, callback) ->
    async.parallel [
      (callback) ->
        db.Article
          .findById article
          .populate "ingestedCorpus"
          .exec callback
      (callback) ->
        async.waterfall [
          (callback) ->
            db.SaturationRecord
              .find
                article: article
                proportion: $gt: 0
              .populate "topic", "words inferencer"
              .exec callback
          (saturationRecords, callback) ->
            db.Inferencer.populate saturationRecords,
              path: "topic.inferencer"
              select: "ingestedCorpus numTopics"
              callback
          (saturationRecords, callback) ->
            db.IngestedCorpus.populate saturationRecords,
              path: "topic.inferencer.ingestedCorpus"
              select: "name"
              callback
        ], callback
    ], (err, [article, saturationRecords]) ->
      return console.error err if err?
      article =
        _id: article._id
        name: article.name
        ingestedCorpus: article.ingestedCorpus.name
      topics = saturationRecords.map (x) ->
        topic:
          _id: x.topic._id
          name:
            x.topic.name ?
            x.topic.words[0...3]
              .map (x) -> x.word
              .concat "…"
              .join ", "
          inferencer:
            ingestedCorpus: x.topic.inferencer.ingestedCorpus.name
            numTopics: x.topic.inferencer.numTopics
        proportion: x.proportion
      callback { article, topics }

module.exports = asyncCaller
  mountPath: "/async-calls/graph-nodes"
  calls: graphNodes
  shouldCache: true
