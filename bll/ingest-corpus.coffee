childProcess = require "child_process"
db = require "../db"
fs = require "node-fs"

{dataPath, malletPath} = require "../constants"

runProcess = (input, output, pipeFrom, regexToken, callback) ->
  childProcess.exec d = """
    #{malletPath} import-dir
      --input #{input}
      --output #{output}
      #{if pipeFrom? then "--use-pipe-from #{pipeFrom}" else ""}
      --token-regex '#{regexToken}'
      --keep-sequence
      --remove-stopwords
  """.replace(/[\n\r]+/g, " "), (err, stdout, stderr) ->
    console.log d
    return console.error err if err?
    callback()

ingestCorpus = (name, regexToken, callback) ->
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
        runProcess input, output, pipeFrom, regexToken, callback

module.exports = ingestCorpus
