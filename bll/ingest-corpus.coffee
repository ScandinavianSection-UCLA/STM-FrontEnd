childProcess = require "child_process"
db = require "../db"
fs = require "node-fs"

{dataPath, malletPath} = require "../constants"

runProcess = (input, output, pipeFrom, regexToken, removeStopwords,
  stopwordsPath, callback) ->
    childProcess.exec d = """
      #{malletPath} import-dir
        --input #{input}
        --output #{output}
        #{if pipeFrom? then "--use-pipe-from #{pipeFrom}" else ""}
        --token-regex '#{regexToken}'
        --keep-sequence
        #{if removeStopwords then "--remove-stopwords" else ""}
        #{if stopwordsPath? then "--stoplist-file '#{stopwordsPath}'" else ""}
    """.replace(/[\n\r]+/g, " "), (err, stdout, stderr) ->
      console.log d
      return console.error err if err?
      callback()

saveStopwords = (ic, icDir, stopwords, callback) ->
  if stopwords.type is "Custom" and stopwords.text?
    fs.writeFile "#{icDir}/#{ic._id}.stopwords", stopwords.text, (err) ->
      return console.error err if err?
      callback "Custom"
  else if stopwords.type is "Custom"
    callback "None"
  else
    callback "English"

ingestCorpus = (name, regexToken, stopwords, callback) ->
  db.IngestedCorpus
    .findOne(name: name)
    .populate("corpus")
    .exec (err, ic) ->
      return console.error err if err?
      input = "#{dataPath}/files/#{ic.corpus._id}/"
      icDir = "#{dataPath}/ingested-corpora"
      output = "#{icDir}/#{ic._id}.mallet"
      pipeFrom = "#{icDir}/#{ic.dependsOn}.mallet" if ic.dependsOn?
      saveStopwords ic, icDir, stopwords, (stopwords) ->
        removeStopwords = stopwords in ["English", "Custom"]
        stopwordsPath = "#{icDir}/#{ic._id}.stopwords" if stopwords is "Custom"
        fs.mkdir icDir, "0777", true, (err) ->
          return console.error err if err?
          runProcess input, output, pipeFrom, regexToken, removeStopwords,
            stopwordsPath, callback

module.exports = ingestCorpus
