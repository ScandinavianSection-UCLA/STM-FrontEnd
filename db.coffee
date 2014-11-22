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

exports.Inferencer = metaDB.model "Inferencer",
  new mongoose.Schema(
    ingestedCorpus: type: mongoose.Schema.ObjectId, ref: "IngestedCorpus"
    numTopics: Number
    topicReport: type: mongoose.Schema.ObjectId, ref: "TopicReport"
    status: String
  ), "inferencers"

exports.TopicsInferred = metaDB.model "TopicsInferred",
  new mongoose.Schema(
    ingestedCorpus: type: mongoose.Schema.ObjectId, ref: "IngestedCorpus"
    numTopics: Number
    status: String
  ), "topicsInferred"

exports.TopicReport = metaDB.model "TopicReport",
  new mongoose.Schema(
    topics: [
      id: Number
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
    ]
  ), "topicReports"
