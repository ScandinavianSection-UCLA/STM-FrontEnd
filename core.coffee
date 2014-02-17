mongoose = require "mongoose"
async = require "async"
xml2js = require "xml2js"
fs = require "fs"

corpus = "english"
subCorpus = "1888"

mongoose.connect "/tmp/mongodb-27017.sock/stm_#{corpus}"

Topic = mongoose.model "Topic", new mongoose.Schema
	id: type: Number
	name: String

Record = mongoose.model "SubCorpus_#{subCorpus}", new mongoose.Schema
	article_id: String
	topic: type: mongoose.Schema.ObjectId, ref: "Topic"
	proportion: Number

exports.getTopicsList = (callback) ->
	Topic.find {}, (err, topics) ->
		return callback err if err?
		callback null, topics.map (topic) ->
			name: topic.name
			id: topic.id

exports.getTopicDetails = (id, callback) ->
	Topic.findOne id: id, (err, topic) ->
		return callback err if err?
		fs.readFile "/home/gotemb/topic1/1888topicphrasereport.xml", encoding: "utf8", (err, doc) ->
			return callback err if err?
			xml2js.parseString doc, (err, {topics: {topic: doc}}) ->
				return callback err if err?
				topicXML = doc.filter((x) -> x.$.id is "#{id}")[0]
				Record.distinct("article_id", topic: topic._id).sort(proportion: -1).limit(30).exec (err, records) ->
					return callback err if err?
					callback null,
						id: topic.id
						name: topic.name
						words: topicXML.word.map (x) ->
							word: x._
							weight: Number x.$.weight
							count: Number x.$.count
						phrases: topicXML.phrase.map (x) ->
							phrase: x._
							weight: Number x.$.weight
							count: Number x.$.count
						records: records.map (x) ->
							article_id: x.article_id
							proportion: x.proportion

exports.getArticle = (article_id, callback) ->
	fs.readFile "/home/gotemb/topic1/1888/#{article_id}.txt", encoding: "utf8", (err, doc) ->
		return callback err if err?
		callback null,
			article_id: article_id
			article: doc

# Deprecated
exports.getTopics = (callback) ->
	fs.readFile "/home/gotemb/topic1/1888topicphrasereport.xml", encoding: "utf8", (err, doc) ->
		xml2js.parseString doc, (err, {topics: {topic: doc}}) ->
			Topic.find {}, (err, topics) ->
				async.map topics, (topic, callback) ->
					Record.find(topic: topic._id).sort(proportion: -1).limit(30).exec (err, records) ->
						callback err,
							topic: topic.toJSON()
							records: records.map (x) -> x.toJSON()
							words:
								doc.filter((x) -> topic.id is Number x.$.id)[0].word.map (x) ->
									word: x._
									weight: Number x.$.weight
									count: Number x.$.count
							phrases:
								doc.filter((x) -> topic.id is Number x.$.id)[0].phrase.map (x) ->
									phrase: x._
									weight: Number x.$.weight
									count: Number x.$.count
				, callback