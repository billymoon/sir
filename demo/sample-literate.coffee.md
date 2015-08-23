# Literate coffee-script

This is both markdown, and coffeescript in one file!

    rnd = (x)-> Math.round Math.random() * x

    console.log rnd 10

When rendered as markdown, it provides documentation. When rendered by coffee-script, it compiles to javascript, stripping the markdown comments :)

    alert 'check out the console...'