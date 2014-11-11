mongoose = require "mongoose"

metaDB = mongoose.createConnection "/tmp/mongodb-27017.sock/stm"

exports.Corpus = metaDB.model "Corpus",
  new mongoose.Schema(
    name: String
    type: String
  ), "corpora"
