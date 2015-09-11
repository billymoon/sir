# Sir

## The polite development server

- serves as plain or pre-processed (on-the-fly):
  - coffee-script
  - less
  - sass/scss
  - stylus
  - markdown
  - jade
  - slim
- literate style coffee-script, js, jade, slim, stylus, etc... even md :-) all à la coffee script litrate style (via [npm/illiterate](https://www.npmjs.com/package/illiterate))
- CORS
- request logging
- beautified pre-processor output
- livereload
- execute shell command on request
- save cache of requested files (useful for pre-processed output)
- path based proxy (useful to proxy to api server, or assets from live site)
- multiple server roots
- aliased server roots

## Installation

    $ npm install -g sir

## Usage

    Usage: sir [options] <dir>

    Options:

      -h, --help                  output usage information
      -V, --version               output the version number
      -p, --port <port>           specify the port [8080]
      -h, --hidden                enable hidden file serving
          --cache <cache-folder>  store copy of each served file in `cache` folder
          --no-livereload         disable livereload watching served directory (add `lr` to querystring of requested resource to inject client script)
          --no-logs               disable request logging
      -f, --format <fmt>          specify the log format string (npmjs.com/package/morgan)
          --compress              gzip or deflate the response
          --exec <cmd>            execute command on each request
          --no-cors               disable cross origin access serving

## Examples

HTTP Accept support...
 
Assuming server runnung with something like... `sir .`

     $ curl http://localhost:8080/ -H "Accept: text/plain"
     bin
     History.md
     node_modules
     ...

Requesting a file:

    $ curl http://localhost:8080/Readme.md
    # Sir
    
    ## The polite development server
    ...

Requesting JSON for the directory listing:

    $ curl http://localhost:8080/ -H "Accept: application/json"
    [
      "bin",
      "History.md",
      "node_modules"
      ...
    ]

## Extra Awesomeness

You can install of vendor libraries to be additionally served up from a `vendor` folder...

    $ cd $(sire --vendor-path)
    $ npm run fetch -- moment underscore
    $ npm run vendor

Now you can run `sir . vendor:$(sir --vendor-path)`, with vendor files served from `http://localhost:8080/vendor`.

(this feature uses [bower-installer](https://github.com/blittle/bower-installer) under the hood)

**N.B.** this feature should be moved into a `sir` command - something like `sir fetch moment` - pull requests welcome :)

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
