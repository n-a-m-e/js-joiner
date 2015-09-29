# js-joiner

Atom plugin for joining together JS files if a mark is present in the current open file

## Usage

Add a comment on the first line of your 'trigger' file with the following format: 

``` 
//js-joiner out: relative/path/to/pack.js, files: relative/path/to/file1.js relative/path/to/file2.js relative/path/to/file3.js
```

Optionally, you can add a 'compress' key into the comment, like so

```
//js-joiner out: rel/path/to/pack.js, files: /rel/path/to/file.js /rel/path/to/file2.js, compress: true
```

Which is going to pass the entire thing out to uglifyJS2 for compressing

Then just save the file normally. Every time you save this marked file, the "out" file will be regenerated from it.