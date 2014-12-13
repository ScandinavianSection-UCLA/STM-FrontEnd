async = require "async"
bs = require "binary-search"
childProcess = require "child_process"
db = require "../db"
fs = require "node-fs"
split = require "split"

{dataPath, malletPath} = require "../constants"

runProcess = (inferencerFilename, input, output, callback) ->
  childProcess.exec d = """
    #{malletPath} infer-topics
      --inferencer #{inferencerFilename}
      --input #{input}
      --output-doc-topics #{output}
      --random-seed 1
  """.replace(/[\n\r]+/g, " "), (err, stdout, stderr) ->
    console.log d
    return console.error err if err?
    callback()

saveMeasuring = (file, name, numTopics, callback) ->
  async.auto
    ingestedCorpus: (callback) ->
      db.IngestedCorpus.findOne
        name: name
        callback
    inferencer: ["ingestedCorpus"
      (callback, {ingestedCorpus}) ->
        db.Inferencer.findOne
          ingestedCorpus: ingestedCorpus.dependsOn ? ingestedCorpus._id
          numTopics: numTopics
          callback
    ]
    topicsInferred: ["ingestedCorpus", "inferencer"
      (callback, {ingestedCorpus, inferencer}) ->
        db.TopicsInferred.findOne
          ingestedCorpus: ingestedCorpus._id
          inferencer: inferencer._id
          callback
    ]
    topics: ["inferencer"
      (callback, {inferencer}) ->
        db.Topic.find
          inferencer: inferencer._id
          callback
    ], (err, {topicsInferred, topics, ingestedCorpus}) ->
      topicsHash = {}
      for topic in topics
        topicsHash[topic.id] = topic
      saturationRecordsCargo = async.cargo (records, callback) ->
        bulk = db.SaturationRecord.collection.initializeUnorderedBulkOp()
        bulk.insert record for record in records
        bulk.execute callback
      , 1000
      articlesCargo = async.cargo (articles, callback) ->
        bulk = db.Article.collection.initializeUnorderedBulkOp()
        bulk.insert article.toObject() for article in articles
        bulk.execute callback
      , 1000
      processArticlesCargo = async.cargo (jobs, callback) ->
        articleIDs = jobs.map (x) -> x.articleID
        db.Article
          .find
            name: $in: articleIDs
            ingestedCorpus: ingestedCorpus._id
            "_id name"
          .sort "name"
          .exec (err, articles) ->
            return console.error err if err?
            articleIDs = articles.map (x) -> x.name
            for job in jobs
              idx = bs articleIDs, job.articleID, (a, b) ->
                if a is b then 0
                else if a < b then -1
                else 1
              if idx < 0
                article =
                  new db.Article
                    name: job.articleID
                    ingestedCorpus: ingestedCorpus._id
                articlesCargo.push article
                job.exec article
              else
                article = articles[idx]
                job.exec article
            callback()
      , 10000
      firstLineDone = false
      fs.createReadStream file, encoding: "utf8"
        .pipe split()
        .on "data", (line) ->
          return if line is ""
          return firstLineDone = true unless firstLineDone
          line = line.split "\t"
          line.shift()
          articleID = line.shift()
          articleID = articleID.split("/")[-1..][0]
          articleID = decodeURIComponent articleID
          processArticlesCargo.push
            articleID: articleID
            exec: (article) ->
              line = line.filter (x) -> x isnt ""
              if line.length is 2 * Object.keys(topicsHash).length
                for i in [0...line.length] by 2
                  saturationRecordsCargo.push
                    topicsInferred: topicsInferred._id
                    article: article._id
                    topic: topicsHash[line[i]]._id
                    proportion: Number line[i + 1]
              else
                for prob, i in line
                  saturationRecordsCargo.push
                    topicsInferred: topicsInferred._id
                    article: article._id
                    topic: topicsHash[i]._id
                    proportion: Number prob
      saturationRecordsCargo.drain = ->
        callback()

inferTopicSaturation = (name, numTopics, callback) ->
  db.IngestedCorpus.findOne name: name, (err, ic) ->
      return console.error err if err?
      inferencerDir = "#{dataPath}/inferencers"
      icInferencer = ic.dependsOn ? ic._id
      inferencerFilename =
        "#{inferencerDir}/#{icInferencer}_#{numTopics}.mallet"
      input = "#{dataPath}/ingested-corpora/#{ic._id}.mallet"
      measuringDir = "#{dataPath}/measuring"
      output = "#{measuringDir}/#{ic._id}_#{numTopics}.txt"
      fs.mkdir measuringDir, "0777", true, (err) ->
        return console.error err if err?
        runProcess inferencerFilename, input, output, ->
          saveMeasuring output, name, numTopics, callback

module.exports = inferTopicSaturation
