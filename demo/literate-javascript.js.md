<link rel='stylesheet' type='text/css' href='literate-sass.css' />

# Literate javascript

This is both markdown, and javascript in one file!

    var rnd = function(x) {
      return Math.round(Math.random() * x);
    }

    console.log(rnd(10));

When rendered as markdown, it provides documentation. When rendered as javascript, it becomes executable code :)

    alert('Super, check out the console...');