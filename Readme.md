# sir

Simple command line development server forked from [serve](https://github.com/visionmedia/serve) and with added features and modifications:

- added coffee-script
- added markdown
- general approach to preparsed files
- address preprocessed files by source name for source as text/plain
- address preprocessed files by compiled name for compiled code
- preprocessed code is rendered on the fly

## Installation

    $ npm install -g sir

## Usage


    Usage: sir [options] [dir]

    Options:

      -h, --help            output usage information
      -V, --version         output the version number
      -F, --format <fmt>    specify the log format string
      -p, --port <port>     specify the port [3000]
      -H, --hidden          enable hidden file serving
      -S, --no-stylus       disable stylus rendering
      -J, --no-jade         disable jade rendering
          --no-less         disable less css rendering
          --no-coffee       disable coffee script rendering
          --no-markdown     disable markdown rendering
      -I, --no-icons        disable icons
      -L, --no-logs         disable request logging
      -D, --no-dirs         disable directory serving
      -f, --favicon <path>  serve the given favicon
      -C, --cors            allows cross origin access serving
          --compress        gzip or deflate the response
          --exec <cmd>      execute command on each request

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
