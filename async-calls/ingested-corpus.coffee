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
      callback corpus?

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
          { $setOnInsert: newIngestedCorpus }, (err, n, res) ->
            return console.error err if err?
            callback !res.updatedExisting

  updateStatus: (name, status, callback) ->
    db.IngestedCorpus.update { name: name }, { status: "done" },
      (err, n, res) ->
        return console.error err if err?
        callback res.updatedExisting

module.exports = asyncCaller
  mountPath: "/async-calls/ingested-corpus"
  calls: ingestedCorpus
