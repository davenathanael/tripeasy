import tripeasy/app_context
import wisp

pub fn handle_request(req: wisp.Request, ctx: app_context.Context) {
  use req <- middleware(req, ctx)

  case wisp.path_segments(req) {
    [] -> todo
    [_, ..] -> todo
  }
}

fn middleware(
  req: wisp.Request,
  ctx: app_context.Context,
  handler: fn(wisp.Request) -> wisp.Response,
) -> wisp.Response {
  let req = wisp.method_override(req)

  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.csrf_known_header_protection(req)
  use req <- wisp.handle_head(req)

  use <- wisp.serve_static(
    req,
    under: ctx.config.static_path,
    from: ctx.config.priv_static_directory,
  )

  handler(req)
}
