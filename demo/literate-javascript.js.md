<link rel='stylesheet' type='text/css' href='sample-stylus.css' />
<script src='./literate-javascript.js'></script>

# Literate javascript

This is both markdown, and javascript in one file!

    var rnd = function(x) {
      return Math.round(Math.random() * x);
    }

When rendered as markdown, it provides documentation. When rendered as javascript, it becomes executable code :)

    console.log(rnd(10));
