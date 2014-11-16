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
  ), "ingested-corpora"
