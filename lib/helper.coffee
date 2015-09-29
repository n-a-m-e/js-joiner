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

path = require 'path'
fs   = require 'fs'

module.exports = Helper =
  directoryName: (file) ->
    path.dirname(file)

  absolutePath: (root, file) ->
    path.join(root, file)

  saveFile: (name, contents) ->
    fs.writeFileSync(name, contents, encoding: "utf-8");

  getFileContents: (root, file_name) ->
    self    = this
    abs     = path.join(root, file_name)
    is_dir  = fs.statSync(abs).isDirectory()

    return unless fs.existsSync(abs)

    if(is_dir)
      files = fs
        .readdirSync(abs)
        .map( (file) -> self.getFileContents(abs, file))
      console.log('found these', files)
      return files
    else
      return fs.readFileSync(abs)

  hasJoinerComment: (line) ->
    re = /^\/\/js\-joiner/
    re.test line

  isJavascriptFile: (file) ->
    re = /\.js$/
    re.test file

  parseJoinerComment: (line) ->
    trim   = (str) -> str.replace(/^\s+|\s+$/g, "")
    outer  = {}
    joiner_str = line.indexOf('js-joiner') + "js-joiner".length
    params = trim line.substr(joiner_str)
      .split(',')
      .map((command) -> command.split(':'))
      .map((block) -> block.map(trim))
      .reduce((was, cur, pos, ar) ->
        if(was[0])
          outer[was[0]] = was[1]
        if(cur[0])
          outer[cur[0]] = cur[1]
        outer;
      , [])
