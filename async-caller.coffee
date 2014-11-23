request = require "superagent"

makeRestInterface = (calls, mountPath) ->
  restInterface = {}
  for name of calls then do (name) ->
    restInterface[name] = (args..., callback) ->
      args.push callback if typeof callback isnt "function"
      request
        .post("#{mountPath}/#{name}")
        .send(args: args, callback: typeof callback is "function")
        .set("Accept", "application/json")
        .end (err, res) ->
          return console.error err if err?
          callback? res.body.result...
  restInterface

makeRouter = (calls, mountPath) -> ({express, bodyParser}) ->
  router = express.Router()
  router.use bodyParser.json()
  for name, func of calls then do (name, func) ->
    router.post "#{mountPath}/#{name}", (req, res, next) ->
      if req.body.callback
        func req.body.args..., ->
          res.json result: Array.prototype.slice.call arguments
      else
        func req.body.args...
        res.end()

module.exports = ({calls, mountPath}) ->
  router: makeRouter calls, mountPath
  calls:
    if typeof window isnt "undefined"
      makeRestInterface calls, mountPath
    else
      calls
