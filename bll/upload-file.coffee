async = require "async"
childProcess = require "child_process"
dataPath = require("../constants").dataPath
db = require "../db"
filesIO = require "../io/files-io"
fs = require "node-fs"
md5 = require "MD5"
os = require "os"
queue = require "queue"
replaceStream = require "replacestream"

childProcessQ = queue concurrency: 16
fdQ = queue concurrency: 256

isFileText = (filePath, preprocessed, theCallback) ->
  return theCallback true if preprocessed
  childProcessQ.push (cb) ->
    callback = (res) ->
      theCallback res
      cb()
    childProcess.exec "file #{filePath}", (err, stdout, stderr) ->
      if err?
        console.error "#{err}: #{stdout.toString "utf8"}"
        return callback false
      regex = /text/i
      callback stdout.toString("utf8").toLowerCase().match(regex)?
  childProcessQ.start()

testAndMoveWithDuplicates =
  (sourceFile, targetFile, preprocessed, theCallback) ->
    rec = (i) ->
      tf =
        if i is 0 then targetFile
        else "#{targetFile} (#{i})"
      fs.stat tf, (err, stat) ->
        if err?
          fdQ.push (cb) ->
            callback = (err, res) ->
              theCallback err, res
              cb err, res
            fs.createReadStream sourceFile, encoding: "utf8"
              .pipe replaceStream /[&"'<>]+/g, " "
              .pipe fs.createWriteStream tf, encoding: "utf8"
              .on "finish", callback
          fdQ.start()
        else
          rec i + 1
    isFileText sourceFile, preprocessed, (result) ->
      if result then rec 0
      else fs.unlink sourceFile, -> callback "Not a text file"

flattenAndMove = (sourceDir, targetDir, preprocessed, callback) ->
  iterator = (file, callback) ->
    sourcePath = "#{sourceDir}/#{file}"
    targetPath = "#{targetDir}/#{file}"
    fs.stat sourcePath, (err, stat) ->
      if err?
        console.error err
        return callback err
      if stat.isDirectory()
        flattenAndMove sourcePath, targetDir, preprocessed, ->
          callback()
      else
        testAndMoveWithDuplicates sourcePath, targetPath, preprocessed, ->
          callback()
  fs.readdir sourceDir, (err, files) ->
    console.error err if err?
    async.each files, iterator, -> callback()

isFileArchive = (filePath, callback) ->
  childProcess.exec "file #{filePath}", (err, stdout, stderr) ->
    return console.error "#{err}: #{stderr.toString "utf8"}" if err?
    regex = /(compress)|(zip)|(archive)|(tar)/i
    callback stdout.toString("utf8").toLowerCase().match(regex)?

extractArchive = (archivePath, extractDir, callback) ->
  bytesDone = 0
  fs.mkdir extractDir, "0777", true, (err) ->
    return console.error err if err?
    tarProcess = childProcess.spawn "bsdtar", ["-xf", "-", "-C", extractDir]
    fin = fs.createReadStream archivePath
    fin.on "data", (chunk) ->
      bytesDone += chunk.length
      callback message: "progress", bytesDone: bytesDone
      fin.pause() unless tarProcess.stdin.write chunk
    fin.on "end", ->
      tarProcess.stdin.end()
    tarProcess.stdin.on "drain", ->
      fin.resume()
    tarProcess.on "exit", (code, signal) ->
      callback message: "extracted"

handleArchive = (file, corpusFilesDir, preprocessed, callback) ->
  hash = md5 "#{file.path}/#{Math.random()}"
  tmpDir = "#{os.tmpdir()}/#{hash}"
  callback status: "extracting", hash: hash
  extractArchive file.path, tmpDir, (update) ->
    filesIO.emit hash, update
    if update.message is "extracted"
      async.parallel [
        (callback) ->
          flattenAndMove tmpDir, corpusFilesDir, preprocessed, callback
        (callback) ->
          fs.unlink file.path, callback
      ], -> filesIO.emit hash, message: "done"

handleSingleFile = (file, corpusFilesDir, preprocessed, callback) ->
  testAndMoveWithDuplicates file.path, "#{corpusFilesDir}/#{file.originalname}",
    preprocessed, (err) ->
      callback status: unless err? then "done" else "failure"

module.exports = ({file, corpusName, corpusType, preprocessed}, callback) ->
  db.Corpus.findOne name: corpusName, type: corpusType, (err, corpus) ->
    return console.error err if err?
    return callback status: failure unless corpus?
    corpusFilesDir = "#{dataPath}/files/#{corpus._id}"
    fs.mkdir corpusFilesDir, "0777", true, (err) ->
      return console.error err if err?
      isFileArchive file.path, (result) ->
        if result
          handleArchive file, corpusFilesDir, preprocessed, callback
        else
          handleSingleFile file, corpusFilesDir, preprocessed, callback
