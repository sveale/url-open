{CompositeDisposable} = require 'atom'

cp = null
async = null
fs = null
os = null
path = null
request = null
Q = null
validurl = null

module.exports = UrlOpen =
  subscriptions: null

  activate: (state) ->
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-workspace', 'url-open:toggle': => @toggle()

  deactivate: ->
    @subscriptions.dispose()

  serialize: ->

  toggle: ->
    cp ?= require 'copy-paste'
    async ?= require 'async'
    fs ?= require 'fs'
    os ?= require 'os'
    path ?= require 'path'
    request ?= require 'request'
    validurl ?= require 'valid-url'

    async.waterfall([
      (callback) ->
        fs.realpath(os.tmpDir(), callback)
      (tmpDir, callback) ->
        tmpDir = "#{tmpDir}#{path.sep}url-open"
        fs.mkdir(tmpDir, (err) ->
          if err? and err.code is 'EEXIST'
            callback(null, tmpDir)
          else
            callback(err, tmpDir)
        )
      (tmpDir, callback) ->
        cp.paste((err, uri) -> callback(err, tmpDir, uri))
      (tmpDir, uri, callback) ->
        if validurl.isWebUri(uri)
          callback(null, tmpDir, uri)
        else
          callback(new Error("Invalid URL!"))
      (tmpDir, uri, callback) ->
        file = fs.createWriteStream("#{tmpDir}#{path.sep}#{path.basename(uri)}")

        request
          .get(uri)
          .on('error', (err) -> callback(err))
          .pipe(file)

        file.on('finish', ->
          file.close((err) ->
            callback(err, file.path)
          )
        )
    ], (err, path) ->
      if err?
        console.error err
      else
        Q ?= require 'q'
        promise = atom.workspace.open(path)
        promise.then((resolved) ->
          resolved.onDidDestroy(->
            fs.unlink(path)
          )
        )
    )
