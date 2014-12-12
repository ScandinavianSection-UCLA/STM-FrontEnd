asyncCaller = require "../async-caller"
db = require "../db"
ingestCorpus = require "../bll/ingest-corpus"
ingestedCorpusCalls = require("./ingested-corpus").calls
ingestIO = require "../io/ingest-io"
md5 = require "MD5"

processCorpus =
  process: (name, corpus, dependsOnName, regexToken, callback) ->
    ingestedCorpusCalls.insert name, corpus, dependsOnName, (result) ->
      return callback false unless result
      ingestCorpus name, regexToken, ->
        ingestedCorpusCalls.updateStatus name, "done", (result) ->
          ingestIO.emit md5(name), message: "done" if result
      callback true

module.exports = asyncCaller
  mountPath: "/async-calls/process-corpus"
  calls: processCorpus
