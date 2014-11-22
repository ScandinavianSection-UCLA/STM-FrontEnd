async = require "async"
asyncCaller = require "../async-caller"
db = require "../db"

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
      .findOne(name: name)
      .populate("corpus dependsOn")
      .exec (err, ingestedCorpus) ->
        return console.error err if err?
        callback
          corpus:
            name: ingestedCorpus?.corpus.name
            type: ingestedCorpus?.corpus.type
          dependsOn: ingestedCorpus?.dependsOn?.name
          status: ingestedCorpus?.status

  getTMStatus: (name, numTopics, callback) ->
    db.IngestedCorpus
      .findOne(name: name)
      .populate("dependsOn")
      .exec (err, ingestedCorpus) ->
        return console.error err if err?
        icInferencer = ingestedCorpus.dependsOn ? ingestedCorpus
        async.parallel [
          (callback) -> db.Inferencer.findOne
            ingestedCorpus: icInferencer._id
            numTopics: numTopics
            callback
          (callback) -> db.TopicsInferred.findOne
            ingestedCorpus: ingestedCorpus._id
            numTopics: numTopics
            callback
        ], (err, [inferencer, topicsInferred] = []) ->
          return console.error err if err?
          callback
            inferencer: inferencer?.status
            topicsInferred: topicsInferred?.status

  updateInferencer: (name, numTopics, obj, callback) ->
    db.IngestedCorpus.findOne name: name, (err, ingestedCorpus) ->
      return console.error err if err?
      query =
        ingestedCorpus: ingestedCorpus._id
        numTopics: numTopics
      db.Inferencer.update query, obj, upsert: true, (err, n, res) ->
        return console.error err if err?
        callback()

  updateTopicsInferredStatus: (name, numTopics, obj, callback) ->
    db.IngestedCorpus.findOne name: name, (err, ingestedCorpus) ->
      return console.error err if err?
      query =
        ingestedCorpus: ingestedCorpus._id
        numTopics: numTopics
      db.TopicsInferred.update query, obj, upsert: true, (err, n, res) ->
        return console.error err if err?
        callback()

module.exports = asyncCaller
  mountPath: "/async-calls/ingested-corpus"
  calls: ingestedCorpus
