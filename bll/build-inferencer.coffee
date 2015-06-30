childProcess = require "child_process"
db = require "../db"
fs = require "node-fs"
os = require "os"
xml2js = require "xml2js"

{dataPath, malletPath} = require "../constants"

runProcess = (input, numTopics, xmlTPR, inferencerFilename, callback) ->
  childProcess.exec d = """
    #{malletPath} train-topics
      --input #{input}
      --num-topics #{numTopics}
      --xml-topic-phrase-report #{xmlTPR}
      --inferencer-filename #{inferencerFilename}
      --random-seed 1
      --num-threads #{os.cpus().length}
  """.replace(/[\n\r]+/g, " "), (err, stdout, stderr) ->
    console.log d
    return console.error err if err?
    callback()

saveXMLTopicPhraseReport = (xmlTPR, inferencer, callback) ->
  fs.readFile xmlTPR, encoding: "utf8", (err, doc) ->
    return console.error err if err?
    xml2js.parseString doc, (err, doc) ->
      return console.error err if err?
      return console.error "Topics not found" unless doc?.topics?.topic?
      topics = doc.topics.topic.map (topic) ->
        inferencer: inferencer
        id: topic.$.id
        hidden: false
        totalTokens: topic.$.totalTokens
        words: topic.word?.map (x) ->
          word: x._
          weight: Number x.$.weight
          count: Number x.$.count
        phrases: topic.phrase?.map (x) ->
          phrase: x._
          weight: Number x.$.weight
          count: Number x.$.count
      db.Topic.create topics, (err) ->
        return console.error err if err?
        callback()

buildInferencer = (name, numTopics, callback) ->
  db.IngestedCorpus.findOne name: name, (err, ic) ->
    return console.error err if err?
    inferencerQuery =
      ingestedCorpus: ic._id
      numTopics: numTopics
    db.Inferencer.findOne inferencerQuery, (err, inferencer) ->
      return console.error err if err?
      input = "#{dataPath}/ingested-corpora/#{ic._id}.mallet"
      inferencerDir = "#{dataPath}/inferencers"
      inferencerFilename = "#{inferencerDir}/#{ic._id}_#{numTopics}.mallet"
      xmlTPRDir = "#{dataPath}/xml-topic-phrase-reports"
      xmlTPR = "#{xmlTPRDir}/#{ic._id}_#{numTopics}.xml"
      fs.mkdir inferencerDir, "0777", true, (err) ->
        return console.error err if err?
        fs.mkdir xmlTPRDir, "0777", true, (err) ->
          return console.error err if err?
          runProcess input, numTopics, xmlTPR, inferencerFilename, ->
            saveXMLTopicPhraseReport xmlTPR, inferencer._id, callback

module.exports = buildInferencer
