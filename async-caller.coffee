request = require "superagent"

makeRestInterface = (calls, mountPath) ->
  restInterface = {}
  for name of calls then do (name) ->
    restInterface[name] = (args..., callback) ->
      request
        .post("#{mountPath}/#{name}")
        .send(args: args)
        .set("Accept", "application/json")
        .end (err, res) ->
          return console.error err if err?
          callback res.body.result...
  restInterface

makeRouter = (calls, mountPath) -> ({express, bodyParser}) ->
  router = express.Router()
  router.use bodyParser.json()
  for name, func of calls then do (name, func) ->
    router.post "#{mountPath}/#{name}", (req, res, next) ->
      func req.body.args..., ->
        res.json result: Array.prototype.slice.call arguments

module.exports = ({calls, mountPath}) ->
  mountPath ?= "/async-calls"
  router: makeRouter calls, mountPath
  calls:
    if typeof window isnt "undefined"
      makeRestInterface calls, mountPath
    else
      calls
