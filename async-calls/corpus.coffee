async = require "async"
asyncCaller = require "../async-caller"
dataPath = require("../constants").dataPath
db = require "../db"
fs = require "fs-extra"

corpus =
  getCorpora: (type, callback) ->
    db.Corpus.find type: type, (err, corpora) ->
      return console.error err if err?
      callback corpora.map (x) -> x.name

  validate: (name, type, callback) ->
    db.Corpus.findOne name: name, type: type, (err, corpus) ->
      return console.error err if err?
      callback corpus?

  insert: (name, type, callback) ->
    db.Corpus.update { name: name, type: type },
      { $setOnInsert: name: name, type: type }, { upsert: true },
      (err, n, res) ->
        return console.error err if err?
        callback !res.updatedExisting

  deleteCorpus: (name, type, callback) ->
    deleteIngestedCorpus = (ingestedCorpus, callback) ->
      async.auto
        removeIngestedCorpus: (callback) ->
          db.IngestedCorpus.remove _id: ingestedCorpus._id, callback
        removeIngestedCorpusFile: (callback) ->
          dir = "#{dataPath}/ingestedCorpus"
          ic = ingestedCorpus._id
          fs.remove "#{dir}/#{ic}.mallet", callback
        dependentIngestedCorpora: (callback) ->
          db.IngestedCorpus.find dependsOn: ingestedCorpus._id, callback
        inferencers: (callback) ->
          db.Inferencer.find ingestedCorpus: ingestedCorpus._id, callback
        removeInferencerFiles: ["inferencers", (callback, {inferencers}) ->
          async.each inferencers,
            (inferencer, callback) ->
              dir = "#{dataPath}/inferencers"
              xmlTPRDir = "#{dataPath}/xml-topic-phrase-reports"
              measuringDir = "#{dataPath}/measuring"
              ic = inferencer.ingestedCorpus
              num = inferencer.numTopics
              async.auto
                mallet: (callback) ->
                  fs.remove "#{dir}/#{ic}_#{num}.mallet", callback
                xml: (callback) ->
                  fs.remove "#{xmlTPRDir}/#{ic}_#{num}.xml", callback
                measuring: (callback) ->
                  fs.remove "#{measuringDir}/#{ic}_#{num}.txt", callback
                callback
            callback
        ]
        removeInferencers: (callback) ->
          db.Inferencer.remove ingestedCorpus: ingestedCorpus._id, callback
        removeTopicsInferred: (callback) ->
          db.TopicsInferred.remove ingestedCorpus: ingestedCorpus._id, callback
        (err, {dependentIngestedCorpora}) ->
          async.each dependentIngestedCorpora, deleteIngestedCorpus, callback

    async.auto
      corpus: (callback) ->
        db.Corpus.findOne name: name, type: type, callback
      removeCorpus: ["corpus", (callback, {corpus}) ->
        db.Corpus.remove _id: corpus._id, callback
      ]
      removeFiles: ["corpus", (callback, {corpus}) ->
        fs.remove "#{dataPath}/files/#{corpus._id}", callback
      ]
      ingestedCorpora: ["corpus", (callback, {corpus}) ->
        db.IngestedCorpus.find corpus: corpus._id, callback
      ]
      removeIngestedCorpus: ["ingestedCorpora", (callback, {ingestedCorpora}) ->
        async.each ingestedCorpora, deleteIngestedCorpus, callback
      ]
      (err) ->
        return console.error err if err?
        callback()

module.exports = asyncCaller
  mountPath: "/async-calls/corpus"
  calls: corpus
