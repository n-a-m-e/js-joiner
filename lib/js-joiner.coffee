###
Copyright (c) 2014 Carlos Vergara

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
###

fs         = require 'fs'
path       = require 'path'
Helper     = require './helper'
ed         = null
UglifyJS = require 'uglify-js'

info = (msg) ->
  atom.notifications.addInfo(msg)

err  = (msg) ->
  atom.notifications.addError(msg, dismissable: true)

class JSJoiner
  ed: null
  parts: {}
  constructor: (editor) ->
    if editor?
      ed = editor
    else info "No editor attached."

  maybeJoin: () ->
    if ed?
      lines = ed.getBuffer().getLines()
      first_line = lines.shift()
      if @isJS(ed.getPath()) && @hasJoinerComment(first_line)
        @parts = @parseJoinerComment first_line
        info "You haven't specified a file to output" unless @parts.out?
        info "You haven't specified any files to join" unless @parts.files?

        root = Helper.directoryName(ed.getPath())
        out  = @parts.out
        out  = Helper.absolutePath(root, out)

        @generate(out)
    else
      info "Didn't attach to editor?"

  hasJoinerComment: (line) ->
    Helper.hasJoinerComment(line)

  isJS: (file) ->
    Helper.isJavascriptFile(file)

  parseJoinerComment: (line) ->
    Helper.parseJoinerComment(line)

  collectFileContents: (file) ->
    root = Helper.directoryName(ed.getPath())
    contents = Helper.getFileContents(root, file)

  getUglified: (files) ->
    minified = "/* There may have been an error in one of your files. Uglify balked. */"
    try
      files = files.map (file) -> path.join(Helper.directoryName(ed.getPath()), file)
    catch e
      err "could not find all the files"

    try
      minified = UglifyJS.minify(files).code
    catch e
      err "Uglify balked at your files. One of them might have an error?"

    return minified

  generate: (file_name) ->
    files  = if @parts.files? then @parts.files.split(' ') else []

    info file_name
    if(@parts.compress)
      joined = @getUglified files
    else
      joined = files
        .map( @collectFileContents.bind(this) )
        .join('')

    Helper.saveFile(file_name, joined)

    info "Outputting to: " + file_name

module.exports = Plugin =
  activate: (state) ->
    info "Activated"
    bindToEditor = () ->
      info("Walking through editors")
      atom.workspace.getTextEditors().forEach( (ed) ->
        info("Found an editor for" + ed.getPath())
        if(!ed.$$joiner)
          info("No joiner found")
        joiner = new JSJoiner(editor)
        ed.onDidSave( () -> joiner.maybeJoin() )
        ed.$$joiner == joiner
      )

    atom.workspace.onDidOpen( bindToEditors )
