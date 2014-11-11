asyncCaller = require "../async-caller"
db = require "../db"

metadata =
  getCorpora: (type, callback) ->
    db.Corpus.find type: type, (err, corpora) ->
      return console.error err if err?
      callback corpora.map (x) -> x.name

  validateCorpus: (name, type, callback) ->
    db.Corpus.findOne name: name, type: type, (err, corpus) ->
      return console.error err if err?
      callback corpus?

  insertCorpus: (name, type, callback) ->
    db.Corpus.update { name: corpus, type: type },
      { $setOnInsert: name: corpus, type: type },
      { upsert: true },
      (err, n, res) ->
        return console.error err if err?
        callback null, success: !res.updatedExisting

module.exports = asyncCaller
  mountPath: "/async-calls/metadata"
  calls: metadata
