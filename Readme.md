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
- CORS
- request logging
- beautified pre-processor output
- livereload
- execute shell command on request
- save cache of requested files (useful for pre-processed output)
- multiple 

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

 HTTP Accept support built into `connect.directory()`:
 
     $ curl http://local:3000/ -H "Accept: text/plain"
     bin
     History.md
     node_modules
     package.json
     Readme.md

  Requesting a file:

    $ curl http://local:3000/Readme.md

     # sir
     ...

  Requesting JSON for the directory listing:

    $ curl http://local:3000/ -H "Accept: application/json"
    ["bin","History.md","node_modules","package.json","Readme.md"]

 Directory listing served by connect's `connect.directory()` middleware.

  ![directory listings](http://f.cl.ly/items/100M2C3o0p2u3A0q1o3H/Screenshot.png)

## Extra Awesomeness

You can install of vendor libraries to be additionally served up from a `vendor` folder...

    $ cd node_modules/sir
    $ npm run fetch -- moment underscore
    $ npm run vendor

Now you can run `sir` as usual, and will have the relevant files served from `http://localhost:8080/vendor`.

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
