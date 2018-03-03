const { dependencies } = require('../package')

const linkTemplate = item => `<li><a href="https://npmjs.org/package/${item}">${item}</a></li>`

module.exports = (req, res, next) => {
  res.end(`
  <!DOCTYPE html>
  <html lang="en">
    <head>
      <meta charset="UTF-8" />
      <title>dependencies</title>
    </head>
    <body>
      <ul>
        ${Object.keys(dependencies).map(linkTemplate).join('')}
      </ul>
    </body>
  </html>
  `)
}
