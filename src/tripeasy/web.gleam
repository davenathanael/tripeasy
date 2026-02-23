import sqlight.{type Connection}
import tripeasy/config.{type Config}
import wisp.{type Request, type Response}

pub type Context {
  Context(config: Config, db: Connection)
}

pub fn middleware(
  req: wisp.Request,
  handler: fn(Request) -> Response,
) -> Response {
  let req = wisp.method_override(req)

  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes

  use req <- wisp.handle_head(req)

  handler(req)
}
