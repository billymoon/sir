import minify from 'express-minify'

export default function (app) {
  if (app.program.minify) {
    app.server.use(minify())
  }
}
