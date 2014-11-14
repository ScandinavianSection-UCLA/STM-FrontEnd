bodyParser = require "body-parser"
express = require "express"
multer = require "multer"
uploadFile = require "../bll/upload-file"

router = express.Router()

router.use bodyParser.json()
router.use multer()

router.post "/upload", (req, res, next) ->
  fileParams =
    file: req.files.file
    corpusName: req.body.corpusName
    corpusType: req.body.corpusType
  uploadFile fileParams, (response) ->
      res.json response

module.exports = router
