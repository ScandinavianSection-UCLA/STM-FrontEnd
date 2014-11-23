async = require "async"
asyncCaller = require "../async-caller"
buildInferencer = require "../bll/build-inferencer"
buildInferencerIO = require "../io/build-inferencer-io"
db = require "../db"
extend = require "extend"
inferTopicSaturation = require "../bll/infer-topic-saturation"
inferTopicSaturationIO = require "../io/infer-topic-saturation-io"
ingestedCorpusCalls = require("./ingested-corpus").calls
md5 = require "MD5"
nop = require "nop"

topicModeling =
  process: (name, numTopics) ->
    doBuildInferencer = (inferencerName, callback) ->
      async.waterfall [
        (callback) ->
          ingestedCorpusCalls.updateInferencer inferencerName, numTopics,
            "processing", callback
        (callback) ->
          ingestedCorpusCalls.updateTopicsInferred name, numTopics,
            "pending", callback
        (callback) ->
          buildInferencer inferencerName, numTopics, callback
        (callback) ->
          ingestedCorpusCalls.updateInferencer inferencerName, numTopics,
            "done", callback
      ], callback

    doInferTopicSaturation = (callback) ->
      async.waterfall [
        (callback) ->
          ingestedCorpusCalls.updateTopicsInferred name, numTopics,
            "processing", callback
        (callback) ->
          inferTopicSaturation name, numTopics, callback
        (callback) ->
          ingestedCorpusCalls.updateTopicsInferred name, numTopics, "done",
            callback
      ], callback

    async.waterfall [
      (callback) ->
        db.IngestedCorpus
          .findOne name: name
          .populate "dependsOn"
          .exec callback
      (ic, callback) ->
        ingestedCorpusCalls.getTMStatus name, numTopics, (statuses) ->
          callback null, ic, statuses
      (ic, statuses, callback) ->
        icInferencer = ic.dependsOn ? ic
        unless statuses.inferencer?
          doBuildInferencer icInferencer.name, ->
            callback null, statuses
        else if statuses.inferencer is "processing"
          async.parallel [
            (callback) ->
              ingestedCorpusCalls.updateTopicsInferred name, numTopics,
                "pending", callback
            (callback) ->
              buildInferencerIO.on "#{icInferencer.name}_#{numTopics}", (msg) ->
                callback() if msg is "done"
          ], -> callback null, statuses
        else
          callback null, statuses
      (statuses, callback) ->
        unless statuses.updateTopicsInferred?
          doInferTopicSaturation callback
        else
          callback()
    ], (err) ->
      console.error err if err?

module.exports = asyncCaller
  mountPath: "/async-calls/topic-modeling"
  calls: topicModeling
