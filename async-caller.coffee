md5 = require "MD5"
request = require "superagent"

cacheVersion = 0

makeRestInterface = (calls, mountPath, cache) ->
  restInterface = {}
  for name of calls then do (name) ->
    restInterface[name] = (args..., callback) ->
      args.push callback if typeof callback isnt "function"
      hash = md5 "#{name}/#{JSON.stringify(args)}/#{cacheVersion}" if cache?
      if cache?[hash]?
        callback? cache[hash]...
      else
        request
          .post "#{mountPath}/#{name}"
          .send args: args, callback: typeof callback is "function"
          .set "Accept", "application/json"
          .timeout 1000 * 60 * 60
          .end (err, res) ->
            return console.error err if err?
            cache[hash] = res.body.result if cache?
            callback? res.body.result...
  restInterface

makeCacheChecker = (calls, cache) ->
  cacheChecker = {}
  for name of calls then do (name) ->
    cacheChecker[name] = (args...) ->
      hash = md5 "#{name}/#{JSON.stringify(args)}/#{cacheVersion}"
      cache[hash]?
  cacheChecker

makeRouter = (calls, mountPath) -> ({express, bodyParser}) ->
  router = express.Router()
  router.use bodyParser.json()
  for name, func of calls then do (name, func) ->
    router.post "#{mountPath}/#{name}", (req, res, next) ->
      if req.body.callback
        func.apply calls, req.body.args.concat ->
          res.json result: Array.prototype.slice.call arguments
      else
        func.apply calls, req.body.args
        res.end()

module.exports = ({calls, mountPath, shouldCache}) ->
  cache = if shouldCache then {}
  router: makeRouter calls, mountPath
  calls:
    if typeof window isnt "undefined"
      makeRestInterface calls, mountPath, cache
    else
      calls
  isCached:
    if shouldCache and typeof window isnt "undefined"
      makeCacheChecker calls, cache

module.exports.resetAllCaches = ->
  cacheVersion++
