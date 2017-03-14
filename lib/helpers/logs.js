import morgan from 'morgan'

export default function (app) {
  // # TODO: merge logs and format options
  if (app.program.logs) {
    app.server.use(morgan(app.program.format))
  }
}
