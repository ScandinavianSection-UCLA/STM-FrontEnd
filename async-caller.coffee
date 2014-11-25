request = require "superagent"

bindAllToSelf = (obj) ->
  for name of obj when typeof callback is "function"
    obj[name] = obj[name].bind @
  obj

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
        func.apply calls, req.body.args.concat ->
          res.json result: Array.prototype.slice.call arguments
      else
        func.apply calls, req.body.args
        res.end()

module.exports = ({calls, mountPath}) ->
  # bindAllToSelf calls
  router: makeRouter calls, mountPath
  calls:
    if typeof window isnt "undefined"
      makeRestInterface calls, mountPath
    else
      calls
