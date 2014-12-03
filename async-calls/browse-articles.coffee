async = require "async"
asyncCaller = require "../async-caller"
db = require "../db"

browseArticles =
  getIngestedCorpora: (callback) ->
    db.IngestedCorpus.find status: "done", (err, ingestedCorpora) ->
      return console.error err if err?
      callback ingestedCorpora.map (x) -> x.name

  validateICName: (name, callback) ->
    query =
      name: name
      status: "done"
    db.IngestedCorpus.findOne query, (err, ingestedCorpus) ->
      return console.error err if err?
      callback ingestedCorpus?

module.exports = asyncCaller
  mountPath: "/async-calls/browse-articles"
  calls: browseArticles
