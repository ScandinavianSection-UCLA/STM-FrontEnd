childProcess = require "child_process"
db = require "../db"

{dataPath, malletPath} = require "../constants"

runProcess = (inferencerFilename, input, output, callback) ->
  childProcess.exec d = """
    #{malletPath} infer-topics
      --inferencer #{inferencerFilename}
      --input #{input}
      --output #{output}
      --random-seed 1
      --num-threads 2
  """.replace(/[\n\r]+/g, " "), (err, stdout, stderr) ->
    console.log d
    return console.error err if err?
    callback()

inferTopicSaturation = (name, numTopics, callback) ->
  db.IngestedCorpus
    .findOne(name: name)
    .populate("dependsOn")
    .exec (err, ic) ->
      return console.error err if err?
      inferencerDir = "#{dataPath}/inferencers"
      icInferencer = ic.dependsOn ? ic
      inferencerFilename =
        "#{inferencerDir}/#{icInferencer._id}_#{numTopics}.mallet"
      input = "#{dataPath}/ingested-corpora/#{ic._id}.mallet"
      measuringDir = "#{dataPath}/measuring"
      output = "#{measuringDir}/#{ic._id}_#{numTopics}.txt"
      fs.mkdir measuringDir, "0777", true, (err) ->
        return console.error err if err?
        runProcess inferencerFilename, input, output, ->
          callback()

module.exports = inferTopicSaturation
