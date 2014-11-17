asyncCaller = require "../async-caller"
db = require "../db"
ingestCorpus = require "../bll/ingest-corpus"
ingestIO = require "../io/ingest-io"
ingestedCorpusCalls = require("./ingested-corpus").calls
md5 = require "MD5"

processCorpus =
  process: (name, corpus, dependsOnName, callback) ->
    ingestedCorpusCalls.insert name, corpus, dependsOnName, (result) ->
      return callback false unless result
      ingestCorpus name, ->
        ingestedCorpusCalls.updateStatus name, "done", (result) ->
          ingestIO.emit md5(name), message: "done" if result
      callback true

module.exports = asyncCaller
  mounthPath: "/async-calls/process-corpus"
  calls: processCorpus
