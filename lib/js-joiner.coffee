fs   = require 'fs'
path = require 'path'

info = (msg) ->
  console.log msg

# A collection of functions to simplify the actual plugin code
Helper =

  #Finds out if a given line is a js-joiner comment
  isJoinerComment: (line) ->
    re = /^\/\/js\-joiner/
    re.test(line)

  # Tests is a file is of the JS type or not
  isJS: (file) ->
    re = /\.js$/
    re.test(file)

  # Pass a file, get a directory from it.
  dirFromPath: (file) ->
    return file.replace(/\\/g, '/').replace(/\/[^\/]*\/?$/, '');

  # Finds out if a given resource is a directory
  isDir: (resource) ->
    return fs.statSync(resource).isDirectory()

  # Gets all the JS in a given directory
  getJSInDir: (dir, files) ->
    files = files || []
    dir_files = fs.readdirSync(dir)
    info("Got all files from " + dir)
    for file in dir_files
      actual_file = path.join(dir, file)
      if(@isDir(actual_file))
        info("Had to recurse")
        @getJSInDir(actual_file, files)
      else
        if(@isJS(actual_file))
          info "Added file " + actual_file
          files.push actual_file
    return files

  #Parses a js-joiner comment and gets a hash from it
  parseJoinerComment: (line) ->
    trim   = (str) -> str.replace(/^\s+|\s+$/g, "")
    outer  = {}
    params = trim(line.substr(line.indexOf('js-joiner') + "js-joiner".length))
      .split(',')
      .map((command) -> command.split(':'))
      .map((block) -> block.map(trim))
      .reduce((was, cur, pos, ar) ->
        if(was[0])
          outer[was[0]] = was[1]
        if(cur[0])
          outer[cur[0]] = cur[1]
        return outer;
      , [])

  getAllFilesInPath: (path) ->
    info("Reading everything in " + path)
    @getJSInDir(path)

  joinFiles: (paths, opt) ->
    contents = []
    open_file_dir = Helper.dirFromPath(atom.workspace.getActiveTextEditor().getPath())
    info("Open file dir is" + open_file_dir);
    except = path.resolve(path.join(open_file_dir, opt.except || '.'))
    try
      paths.forEach (file) ->
        if file != except
          contents.push(fs.readFileSync(file).toString())
    catch e
      console.log("EHHH", e)
    return contents.join("\n");

  writeToPath: (name, contents) ->
    info("Writing to path", path.resolve(name), "contents", contents)
    open_file_dir = Helper.dirFromPath(atom.workspace.getActiveTextEditor().getPath())
    name = path.join(open_file_dir, name)
    fs.writeFileSync(name, contents)


module.exports = Plugin =
  activate: (state) ->
    if editor = atom.workspace.getActiveTextEditor()
      editor.onDidSave @tryToJoin

  deactivate: ->
    @subscriptions.dispose()

  tryToJoin: ->
    if editor     = atom.workspace.getActiveTextEditor()
      first_line  = editor.getBuffer().getLines().shift()
      editor_path        = editor.getPath()
      info("Currently on" + editor_path);
      if(Helper.isJS(editor_path) && Helper.isJoinerComment(first_line))
        command   = Helper.parseJoinerComment(first_line)
        if(command.out?)
          info("Outfile:" + command.out)
          paths  = Helper.getAllFilesInPath(Helper.dirFromPath(editor_path))
          info("View console for paths")
          console.log(paths);
          joined = Helper.joinFiles(paths, except: command.out)
          info("View console for joined files")
          Helper.writeToPath(command.out, joined)
          info("Wrote to file " + command.out)
        else console.log("Not.")
    else throw new Error("No editor?")
