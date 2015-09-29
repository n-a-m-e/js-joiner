(function(module){

  "use strict";

  var fs         = require ('fs'),
      path       = require ('path'),
      Helper     = require ('./helper'),
      ed         = null,
      UglifyJS = require ('uglify-js');

  var info = function(msg){
    atom.notifications.addInfo(msg);
  };

  var err = function(msg){
    atom.notifications.addError(msg, {dismissable: true});
  }

  var JSJoiner = function JSJoiner(editor){
    var self = this;

    this.hasJoinerComment = function(line){
      return Helper.hasJoinerComment(line);
    }

    this.isJS = function(file){
      return Helper.isJavascriptFile(file);
    }

    this.parseJoinerComment = function(line){
      return Helper.parseJoinerComment(line);
    }

    if(this.constructor !== JSJoiner){
      throw new Error("Bad instantiation. Please report this");
    }

    this.maybeJoin = function(){
      if(!this.ed) err("Plugin wasn't well attached. Please report this");
      var lines      = this.ed.getBuffer().getLines(),
          first_line = lines.shift(),
          root, out;

      if(this.isJS(this.ed.getPath()) && this.hasJoinerComment(first_line)){
        this.parts = this.parseJoinerComment(first_line);
        if(!this.parts.out){   return info("You haven't specified an output file")    }
        if(!this.parts.files){ return info("You haven't specified any files to join") }

        root = Helper.directoryName(this.ed.getPath());
        out  = Helper.absolutePath(root, this.parts.out);

        this.generate(out);
      }
    };

    this.getUglified = function(files){
      var minified = "/* There may have been an error in one of your files. */";
      try{
        var root = path.dirname(this.ed.getPath());
        files = files.map(function(file){
          return path.join(root, file)
        });
      }
      catch(e){
        err("There was an error reading the files to minify. Are they all there?");
        return minified; //oops
      }

      try{
        return UglifyJS.minify(files).code;
      }
      catch(e){
        err("Uglify balked at your files. One of them might have an error?");
        return minified;
      }
    }

    this.collectFileContents = function(file){
      root = Helper.directoryName(this.ed.getPath())
      return Helper.getFileContents(root, file);
    };

    this.generate = function(file_name){
      var joined, files;
      files = this.parts.files? this.parts.files.split(' ') : [];
      if(!this.parts.compress){
        joined = files.map(this.collectFileContents.bind(this)).join("\n");
      }
      else{
        joined = this.getUglified(files);
      }

      Helper.saveFile(file_name, joined);
      info("Generated " + file_name);
    }

    this.init = function(ed){
      this.ed = ed;
    };

    return this.init(editor);
  };

  module.exports = Plugin = {
    activate: function(){
      var editors = [];
      setInterval(function(){
        var editors_now = atom.workspace.getTextEditors();
        if(editors.length != editors_now.length){
          editors = editors_now;
          atom.workspace.getTextEditors().forEach(function(ed){
            if(!ed.$$joiner){
              ed.$$joiner = new JSJoiner(ed);
              ed.onDidSave(function(){ ed.$$joiner.maybeJoin() })
            }
          });
        }
      },200);
    }
  };

})(module);
