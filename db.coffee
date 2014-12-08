mongoose = require "mongoose"

metaDB = mongoose.createConnection "/tmp/mongodb-27017.sock/stm"

exports.Corpus = metaDB.model "Corpus",
  new mongoose.Schema(
    name: String
    type: String
  ), "corpora"

exports.IngestedCorpus = metaDB.model "IngestedCorpus",
  new mongoose.Schema(
    name: String
    corpus: type: mongoose.Schema.ObjectId, ref: "Corpus"
    dependsOn: type: mongoose.Schema.ObjectId, ref: "IngestedCorpus"
    status: String
  ), "ingestedCorpora"

exports.Article = metaDB.model "Article",
  new mongoose.Schema(
    name: String
    ingestedCorpus: type: mongoose.Schema.ObjectId, ref: "IngestedCorpus"
  ), "articles"

exports.Inferencer = metaDB.model "Inferencer",
  new mongoose.Schema(
    ingestedCorpus: type: mongoose.Schema.ObjectId, ref: "IngestedCorpus"
    numTopics: Number
    status: String
  ), "inferencers"

exports.TopicsInferred = metaDB.model "TopicsInferred",
  new mongoose.Schema(
    ingestedCorpus: type: mongoose.Schema.ObjectId, ref: "IngestedCorpus"
    inferencer: type: mongoose.Schema.ObjectId, ref: "Inferencer"
    status: String
  ), "topicsInferred"

exports.Topic = metaDB.model "Topic",
  new mongoose.Schema(
    inferencer: type: mongoose.Schema.ObjectId, ref: "Inferencer"
    id: Number
    name: String
    totalTokens: Number
    words: [
      word: String
      weight: Number
      count: Number
    ]
    phrases: [
      phrase: String
      weight: Number
      count: Number
    ]
  ), "topics"

exports.SaturationRecord = metaDB.model "SaturationRecord",
  new mongoose.Schema(
    topicsInferred:
      type: mongoose.Schema.ObjectId
      ref: "TopicsInferred"
      index: true
    article:
      type: mongoose.Schema.ObjectId
      ref: "Article"
      index: true
    topic:
      type: mongoose.Schema.ObjectId
      ref: "Topic"
      index: true
    proportion:
      type: Number
      index: true
  ), "saturationRecords"

exports.createTemporaryCollection = ->
  name = "tempCollection#{Date.now()}"
  metaDB.model "TempCollection",
    new mongoose.Schema(
      {}
      strict: false
    ), name
