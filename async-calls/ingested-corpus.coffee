async = require "async"
asyncCaller = require "../async-caller"
buildInferencerIO = require "../io/build-inferencer-io"
db = require "../db"
inferTopicSaturationIO = require "../io/infer-topic-saturation-io"
md5 = require "MD5"

ingestedCorpus =
  getIngestedCorpora: (onlyCompleted, callback) ->
    query = {}
    query.status = "done" if onlyCompleted
    db.IngestedCorpus.find query, (err, ingestedCorpora) ->
      return console.error err if err?
      callback ingestedCorpora.map (x) -> x.name

  validate: (name, onlyCompleted, callback) ->
    query = name: name
    query.status = "done" if onlyCompleted
    db.IngestedCorpus.findOne query, (err, ingestedCorpus) ->
      return console.error err if err?
      callback ingestedCorpus?

  insert: (name, corpus, dependsOnName, callback) ->
    getDependsOn = (callback) ->
      if dependsOnName?
        db.IngestedCorpus.findOne name: dependsOnName, status: "done", callback
      else
        callback()
    db.Corpus.findOne name: corpus.name, type: corpus.type, (err, corpus) ->
      return console.error err if err?
      getDependsOn (err, dependsOn) ->
        return console.error err if err?
        newIngestedCorpus =
          name: name
          corpus: corpus._id
          status: "processing"
        if dependsOnName? and dependsOn?
          newIngestedCorpus.dependsOn = dependsOn._id
        else if dependsOnName?
          return callback false
        db.IngestedCorpus.update { name: name },
          { $setOnInsert: newIngestedCorpus }, { upsert: true },
          (err, n, res) ->
            return console.error err if err?
            callback !res.updatedExisting

  updateStatus: (name, status, callback) ->
    db.IngestedCorpus.update { name: name }, { status: status },
      (err, n, res) ->
        return console.error err if err?
        callback res.updatedExisting

  getDetails: (name, callback) ->
    db.IngestedCorpus
      .findOne name: name
      .populate "corpus dependsOn"
      .exec (err, ingestedCorpus) ->
        return console.error err if err?
        callback
          corpus:
            name: ingestedCorpus?.corpus.name
            type: ingestedCorpus?.corpus.type
          dependsOn: ingestedCorpus?.dependsOn?.name
          status: ingestedCorpus?.status

  getTMStatus: (name, numTopics, callback) ->
    async.waterfall [
      (callback) ->
        db.IngestedCorpus
          .findOne name: name
          .populate "dependsOn"
          .exec callback
      (ingestedCorpus, callback) ->
        icInferencer = ingestedCorpus.dependsOn ? ingestedCorpus
        db.Inferencer.findOne
          ingestedCorpus: icInferencer._id
          numTopics: numTopics
          (err, inferencer) ->
            callback err, ingestedCorpus, inferencer
      (ingestedCorpus, inferencer, callback) ->
        return callback() unless inferencer?
        db.TopicsInferred.findOne
          ingestedCorpus: ingestedCorpus._id
          inferencer: inferencer._id
          (err, topicsInferred) ->
            callback err, inferencer, topicsInferred
    ], (err, inferencer, topicsInferred) ->
      return console.error err if err?
      callback
        inferencer: inferencer?.status
        topicsInferred: topicsInferred?.status

  updateInferencer: (name, numTopics, status, callback) ->
    db.IngestedCorpus.findOne name: name, (err, ingestedCorpus) ->
      return console.error err if err?
      query =
        ingestedCorpus: ingestedCorpus._id
        numTopics: numTopics
      update =
        status: status
      db.Inferencer.update query, update, upsert: true, (err, n, res) ->
        return console.error err if err?
        buildInferencerIO.emit md5("#{name}_#{numTopics}"), status
        callback()

  updateTopicsInferred: (name, numTopics, status, callback) ->
    async.waterfall [
      (callback) ->
        db.IngestedCorpus.findOne name: name, callback
      (ingestedCorpus, callback) ->
        icInferencer = ingestedCorpus.dependsOn ? ingestedCorpus._id
        db.Inferencer.findOne
          ingestedCorpus: icInferencer
          numTopics: numTopics
          (err, inferencer) ->
            callback err, ingestedCorpus, inferencer
      (ingestedCorpus, inferencer, callback) ->
        return callback() unless inferencer?
        query =
          ingestedCorpus: ingestedCorpus._id
          inferencer: inferencer._id
        update =
          status: status
        db.TopicsInferred.update query, update, upsert: true, callback
    ], (err) ->
      return console.error err if err?
      inferTopicSaturationIO.emit md5("#{name}_#{numTopics}"), status
      callback()

module.exports = asyncCaller
  mountPath: "/async-calls/ingested-corpus"
  calls: ingestedCorpus
