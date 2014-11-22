asyncCaller = require "../async-caller"
buildInferencer = require "../bll/build-inferencer"
buildInferencerIO = require "../io/build-inferencer-io"
db = require "../db"
ingestedCorpusCalls = require("./ingested-corpus").calls
md5 = require "MD5"
nop = require "nop"

topicModeling =
  process: (name, numTopics, callback) ->
    buildAndStoreInferencer = (name, numTopics, callback) ->
      buildInferencerIO.emit md5("#{name}_#{numTopics}"), "processing"
      ingestedCorpusCalls.updateInferencer name, numTopics,
        status: "processing", ->
          buildInferencer name, numTopics, ({topicReport}) ->
            update =
              topicReport: topicReport
              status: "done"
            ingestedCorpusCalls.updateInferencer name, numTopics, update, ->
              buildInferencerIO.emit md5("#{name}_#{numTopics}"), "done"
              callback()
    db.IngestedCorpus
      .findOne(name: name)
      .populate("dependsOn")
      .exec (err, ic) ->
        return console.error err if err?
        ic = ic.dependsOn ? ic
        ingestedCorpusCalls.getTMStatus name, numTopics, (statuses) ->
          unless statuses.inferencer?
            buildAndStoreInferencer ic.name, numTopics, nop
            callback inferencer: "processing"
          else
            nop()
            callback inferencer: "done"

module.exports = asyncCaller
  mountPath: "/async-calls/topic-modeling"
  calls: topicModeling
