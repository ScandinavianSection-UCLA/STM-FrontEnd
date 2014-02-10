mongoose = require "mongoose"
async = require "async"
xml2js = require "xml2js"
fs = require "fs"

mongoose.connect "/tmp/mongodb-27017.sock/stm_#{corpus}"

Topic = mongoose.model "Topic", new mongoose.Schema
	id: type: Number
	name: String

Record = mongoose.model "SubCorpus_#{subCorpus}", new mongoose.Schema
	article_id: String
	topic: type: mongoose.Schema.ObjectId, ref: "Topic"
	proportion: Number

exports.getTopics = ->
	fs.readFile "~/Downloads/1888topicphrasereport.xml", encoding: "utf8", (err, doc) ->
		xml2js.parseString doc, (err, {topics: {topic: topics}}) ->
			Topic.find {}, (err, topics) ->
				async.each topics, (topic, callback) ->
					Record.find(topic: topic._id).sort(proportion: -1).limit(30).exec (err, records) ->
						topic: topic.toJSON()
						records: records.map (x) -> x.toJSON()
						words:
							topics.filter((x) -> topic.id is Number x.$.id)[0].word.map (x) ->
								word: x._
								weight: Number x.$.weight
								count: Number x.$.count
						phrases:
							topics.filter((x) -> topic.id is Number x.$.id)[0].phrase.map (x) ->
								phrase: x._
								weight: Number x.$.weight
								count: Number x.$.count