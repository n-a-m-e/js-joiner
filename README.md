# js-joiner

js-joiner joins and optionally compresses any javascript files you need, according to a specially formatted comment that has to be present on the first line of your "trigger" JS file.

## Usage

In the first line of some javascript file that you want to use as "trigger" (this means that whenever this file is saved a new package is generated), add a comment like the following:

```
//js-joiner out: out/file.js, files: file-1.js file-2.js file-3.js, compress: true
```

Where:

* ```out``` is the path to your "package" file, relative to the "trigger" file's directory
* ```files``` is a space-separated list of all the files you want packaged in the order they will appear in the package file
* ```compress``` is an entirely optional key that if added and set to true will uglify the file specified in ```out``` after generation.
