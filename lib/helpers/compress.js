import compression from 'compression'

export default function (app) {
  if (app.program.compress) {
    app.server.use(compression({threshold: 0}))
  }
}
