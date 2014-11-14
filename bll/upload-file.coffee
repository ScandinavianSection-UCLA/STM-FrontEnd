async = require "async"
childProcess = require "child_process"
dataPath = require("../constants").dataPath
db = require "../db"
filesIO = require "../io/files-io"
fs = require "node-fs"
md5 = require "MD5"
os = require "os"

moveWithDuplicates = (sourceFile, targetFile, callback) ->
  rec = (i) ->
    tf =
      if i is 0 then targetFile
      else "#{targetFile} (#{i})"
    fs.stat tf, (err, stat) ->
      if err? then fs.rename sourceFile, tf, callback
      else rec i + 1
  rec 0

flattenAndMove = (sourceDir, targetDir, callback) ->
  iterator = (file, callback) ->
    sourcePath = "#{sourceDir}/#{file}"
    targetPath = "#{targetDir}/#{file}"
    fs.stat sourcePath, (err, stat) ->
      return console.error err if err?
      if stat.isDirectory()
        flattenAndMove sourcePath, targetDir, callback
      else
        moveWithDuplicates sourcePath, targetPath, callback
  fs.readdir sourceDir, (err, files) ->
    return console.error err if err?
    async.each files, iterator, callback

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

handleArchive = (file, corpusFilesDir, callback) ->
  hash = md5 "#{file.path}/#{Math.random()}"
  tmpDir = "#{os.tmpdir()}/#{hash}"
  callback status: "extracting", hash: hash
  extractArchive file.path, tmpDir, (update) ->
    filesIO.emit hash, update
    if update.message is "extracted"
      async.parallel [
        (callback) -> flattenAndMove tmpDir, corpusFilesDir, callback
        (callback) -> fs.unlink file.path, callback
      ], -> filesIO.emit hash, message: "done"

handleSingleFile = (file, corpusFilesDir, callback) ->
  moveWithDuplicates file.path, "#{corpusFilesDir}/#{file.originalname}",
    (err) ->
      return console.error err if err?
      callback status: "done"

module.exports = ({file, corpusName, corpusType}, callback) ->
  db.Corpus.findOne name: corpusName, type: corpusType, (err, corpus) ->
    return console.error err if err?
    return callback status: failure unless corpus?
    corpusFilesDir = "#{dataPath}/files/#{corpus._id}"
    fs.mkdir corpusFilesDir, "0777", true, (err) ->
      return console.error err if err?
      isFileArchive file.path, (result) ->
        if result then handleArchive file, corpusFilesDir, callback
        else handleSingleFile file, corpusFilesDir, callback
