import gleam/erlang/process
import mist
import tripeasy/app_context
import tripeasy/config
import tripeasy/db
import tripeasy/router
import tripeasy/utils.{must}
import wisp
import wisp/wisp_mist

pub fn run() {
  wisp.configure_logger()

  let config = config.load() |> must
  use db <- db.with_connection(config.database_url)
  let context = app_context.Context(config, db)

  let assert Ok(_) =
    wisp_mist.handler(
      router.handle_request(_, context),
      context.config.secret_key_base,
    )
    |> mist.new
    |> mist.port(context.config.port)
    |> mist.start

  process.sleep_forever()
}
