# Literate slim

This is both markdown, and javascript in one file!

    doctype html
    html
      head
        title cool

Set some basic styles using stylus...

        stylus:
          body
            background lighten(gold, 90%)
            font-family sans-serif
            margin 0
            padding 0 20px
            h1
              color darken(red,50%)

Coffeescript is ok too...

        coffee:
          @load = ->
            document.getElementsByClassName('info')[0].innerText = 'seems that coffee works just fine!'

      body onload='load()'
        h1 awesome
        p.info nice one