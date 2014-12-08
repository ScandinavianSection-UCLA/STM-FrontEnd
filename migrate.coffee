db = require "./db"
hashCode = require "./hash-code"

articles = []
currentArticleID = ""
doneNow = 0
doneTotal = 0

db.SaturationRecord
  .find()
  .sort "articleID"
  .populate "topicsInferred"
  .stream()
    .on "data", (doc) ->
      unless doc.articleID is currentArticleID
        articles = []
        currentArticleID = doc.articleID
      hash = hashCode doc.topicsInferred.ingestedCorpus.toString()
      article = articles[hash]
      unless article?
        article = new db.Article
          name: doc.articleID
          ingestedCorpus: doc.topicsInferred.ingestedCorpus
        article.save()
        articles[hash] = article
      doc.article = article
      doc.save()
      doneNow++
    .on "error", console.error
    .on "close", ->
      console.log "All Done!"

setInterval(
  ->
    doneTotal += doneNow
    console.log doneNow, doneTotal
    doneNow = 0
  1000
)
