async = require "async"
asyncCaller = require "../async-caller"
db = require "../db"

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

  validateNumTopicsForIC: (numTopics, name, callback) ->
    async.waterfall [
      (callback) ->
        db.IngestedCorpus.findOne name: name, callback
      (ic, callback) ->
        callback ic._id
      (icID, callback) ->
        db.Inferencer.findOne
          ingestedCorpus: icID
          numTopics: numTopics
          callback
    ], (err, inferencer) ->
      return console.error err if err?
      callback inferencer?

module.exports = asyncCaller
  mountPath: "/async-calls/browse-topics"
  calls: browseTopics
