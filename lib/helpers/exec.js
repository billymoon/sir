import { exec } from 'child_process'

export default function (app) {
  if (app.program.exec) {
    app.server.use((req, res, next) => exec(app.program.exec, next))
  }
}
