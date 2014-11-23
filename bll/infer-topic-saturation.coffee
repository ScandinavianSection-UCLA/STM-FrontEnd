async = require "async"
childProcess = require "child_process"
db = require "../db"
fs = require "node-fs"
split = require "split"

{dataPath, malletPath} = require "../constants"

runProcess = (inferencerFilename, input, output, callback) ->
  childProcess.exec d = """
    #{malletPath} infer-topics
      --inferencer #{inferencerFilename}
      --input #{input}
      --output-doc-topics #{output}
      --random-seed 1
  """.replace(/[\n\r]+/g, " "), (err, stdout, stderr) ->
    console.log d
    return console.error err if err?
    callback()

saveMeasuring = (file, name, numTopics, callback) ->
  async.auto
    ingestedCorpus: (callback) ->
      db.IngestedCorpus.findOne
        name: name
        callback
    inferencer: ["ingestedCorpus"
      (callback, {ingestedCorpus}) ->
        db.Inferencer.findOne
          ingestedCorpus: ingestedCorpus.dependsOn ? ingestedCorpus._id
          numTopics: numTopics
          callback
    ]
    topicsInferred: ["ingestedCorpus", "inferencer"
      (callback, {ingestedCorpus, inferencer}) ->
        db.TopicsInferred.findOne
          ingestedCorpus: ingestedCorpus._id
          inferencer: inferencer._id
          callback
    ]
    topics: ["inferencer"
      (callback, {inferencer}) ->
        db.Topic.find
          inferencer: inferencer._id
          callback
    ], (err, {topicsInferred, topics}) ->
      topicsHash = {}
      for topic in topics
        topicsHash[topic.id] = topic
      cargo = async.cargo (records, callback) ->
        bulk = db.SaturationRecord.collection.initializeUnorderedBulkOp()
        bulk.insert record for record in records
        bulk.execute callback
      , 1000
      firstLineDone = false
      fs.createReadStream file, encoding: "utf8"
        .pipe split()
        .on "data", (line) ->
          return if line is ""
          return firstLineDone = true unless firstLineDone
          line = line.split "\t"
          line.shift()
          articleID = line.shift()
          articleID = articleID.split("/")[-1..][0]
          for prob, i in line
            cargo.push
              topicsInferred: topicsInferred._id
              articleID: articleID
              topic: topicsHash[i]._id
              proportion: Number prob
        cargo.drain = ->
          callback()

inferTopicSaturation = (name, numTopics, callback) ->
  db.IngestedCorpus.findOne name: name, (err, ic) ->
      return console.error err if err?
      inferencerDir = "#{dataPath}/inferencers"
      icInferencer = ic.dependsOn ? ic._id
      inferencerFilename =
        "#{inferencerDir}/#{icInferencer}_#{numTopics}.mallet"
      input = "#{dataPath}/ingested-corpora/#{ic._id}.mallet"
      measuringDir = "#{dataPath}/measuring"
      output = "#{measuringDir}/#{ic._id}_#{numTopics}.txt"
      fs.mkdir measuringDir, "0777", true, (err) ->
        return console.error err if err?
        runProcess inferencerFilename, input, output, ->
          saveMeasuring output, name, numTopics, callback

module.exports = inferTopicSaturation
