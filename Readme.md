# Sir

## The polite development server

- serves as plain or pre-processed on-the-fly: less, sass/scss, stylus, markdown, slim
- livereload
- multiple and aliased server roots
- path based proxy (useful to proxy to api server, or assets from live site)
- request logging (customizable, uses [morgan](npmjs.com/package/morgan))
- beautified pre-processed file output
- execute shell command on request
- save cache of requested files (useful for pre-processed output)
- CORS
- literate style js, slim, stylus, etc... even md :-) all à la litrate coffee script (via [npm/illiterate](https://www.npmjs.com/package/illiterate))

## Installation

    $ npm install -g sir

## Usage

    Usage: sir [options] <dir>

    Options:

      -h, --help                    output usage information
      -V, --version                 output the version number
      -p, --port <port>             specify the port [8080]
      -h, --hidden                  enable hidden file serving
          --backup <backup-folder>  store copy of each served file in `backup` folder
          --no-livereload           disable livereload watching served directory (add `lr` to querystring of requested resource to inject client script)
          --no-logs                 disable request logging
      -f, --format <fmt>            specify the log format string (npmjs.com/package/morgan)
          --minify                  minify code before serving
          --compress                gzip or deflate the response
          --exec <cmd>              execute command on each request
          --no-cors                 disable cross origin access serving
          --babel                   pass all js through babel to convert to more js :)

## Examples

Assuming server runnung with something like... `sir .`

### Requesting a file:

    $ curl http://localhost:8080/Readme.md
    # Sir

    ## The polite development server
    ...

### Requesting a preprocessed version of a file:

Make the same request as if the file had already been compiled, and was being served, and it will be processed on-the-fly...

    $ curl http://localhost:8080/Readme.html
    <h1 id="sir">Sir</h1>
    <h2 id="the-polite-development-server">The polite development server</h2>
    ...

This also works for sass, less, etc...

### Requesting the directory listing:

Add a `format` parameter to querystring, or add an `Accept` paramater header. Valid types are `json`, `text` and `html`.

    $ curl http://localhost:8080/?format=json
    ... or ...
    $ curl http://localhost:8080/ -H "Accept: application/json"
    [
      "bin",
      "History.md",
      "node_modules"
      ...
    ]

Ar for plain text list

    $ curl http://localhost:8080/?format=text
    ... or ...
    $ curl http://localhost:8080/ -H "Accept: text/plain"
    bin
    History.md
    node_modules
    ...

### Livereload

By default, livereload is enabled on the same port as the main server. This should work with the browser's livereload plugin, or adding the `/livereload.js?snipver=1` script to your html (which is served up by the sir). For convenience, adding `lr` to the querystring will inject `<script src="/livereload.js?snipver=1"></script>` into your served file.

... without livereload ...

    $ curl http://localhost:8080/Readme.html
    <h1 id="sir">Sir</h1>
    <h2 id="the-polite-development-server">The polite development server</h2>

... with livereload ...

    $ curl http://localhost:8080/Readme.html?lr
    <script src="/livereload.js?snipver=1"></script>
    <h1 id="sir">Sir</h1>
    <h2 id="the-polite-development-server">The polite development server</h2>

If you don't want the livereload feature enabled at all, then there is a `--no-livereload` flag

### Multiple sources

You can serve up from multiple locations, for example:

    $ sir . vendor:~/lib/vendor

This will serve from the current directory, except requests for `/vendor/myfile.txt` will be served from `~/lib/vendor`.

You can also layer multiple sources into one directory...

    $ sir . vendor:~/lib/vendor:~/other/vendor

This will serve current directory, except paths starting `/vendor/` which will try to serve from `~/lib/vendor` and if the file is not found there, will be served from `~/other/vendor`, ultimately returning 404 if file is not found.

### Proxy

You can proxy requests based on url, for example...

    $ sir . github:https://api.github.com/repos/billymoon/sir

This will serve current directory, except for paths starting `/github/` which will be proxied to `https://api.github.com/repos/billymoon/sir` so that accessing...

    http://localhost:8080/github/issues?state=closed

... will proxy through the response from ...

    https://api.github.com/repos/billymoon/sir/issues?state=closed

### Cache

Useful for saving processed version of source files, for example, if you have `index.slm`, and `style.less` and want to save the html and css, add a `--cache backup` flag, and then visit `http://localhost:8080/index.html` in your browser. There should be a `index.html` and a `style.css` in the backup folder.

### Compress

Add gzip compression to served assets with the `--compress` flag.

## License

(The MIT License)

Copyright (c) 2013 Billy Moon &lt;billy@itaccess.org&gt;

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
