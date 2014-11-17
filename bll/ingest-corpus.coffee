childProcess = require "child_process"
dataPath = require("../constants").dataPath
db = require "../db"
fs = require "node-fs"

runProcess = (input, output, pipeFrom, callback) ->
  childProcess.exec d = """
    mallet import-dir
      --input #{input}
      --output #{output}
      #{"--use-pipe-from #{pipeFrom}" if pipeFrom?}
      --token-regex '\\p{L}[\\p{L}\\p{P}]*\\p{L}'
      --keep-sequence
      --remove-stopwords
  """.replace(/[\n\r]+/g, " "), (err, stdout, stderr) ->
    return console.error err if err?
    callback()

ingestCorpus = (name, callback) ->
  db.IngestedCorpus
    .findOne(name: name)
    .populate("corpus")
    .exec (err, ic) ->
      return console.error err if err?
      input = "#{dataPath}/files/#{ic.corpus._id}/"
      icDir = "#{dataPath}/ingested-corpora"
      output = "#{icDir}/#{ic._id}.mallet"
      pipeFrom = "#{icDir}/#{ic.dependsOn}.mallet" if ic.dependsOn?
      fs.mkdir icDir, "0777", true, (err) ->
        return console.error err if err?
        runProcess input, output, pipeFrom, callback

module.exports = ingestCorpus
