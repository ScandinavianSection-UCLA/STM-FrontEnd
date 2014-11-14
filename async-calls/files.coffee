asyncCaller = require "../async-caller"
dataPath = require("../constants").dataPath
db = require "../db"
fs = require "node-fs"

files =
  getNumFilesInCorpus: (name, type, callback) ->
    db.Corpus.findOne name: name, type: type, (err, corpus) ->
      return console.error err if err?
      return callback 0 unless corpus?
      fs.readdir "#{dataPath}/files/#{corpus._id}", (err, files) ->
        files = [] if err?
        callback files.length

module.exports = asyncCaller
  mountPath: "/async-calls/files"
  calls: files
