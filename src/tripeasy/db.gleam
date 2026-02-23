import gleam/int
import gleam/result
import snag
import sqlight

pub fn with_connection(database_url: String, run: fn(sqlight.Connection) -> Nil) {
  let res = {
    use db <- result.try(
      sqlight.open(database_url)
      |> snag.map_error(describe_sqlite_error)
      |> snag.context("Failed to connect to database"),
    )

    run(db)

    use _ <- result.try(
      sqlight.close(db)
      |> snag.map_error(describe_sqlite_error)
      |> snag.context("Failed to connect to database"),
    )

    Ok(Nil)
  }

  case res {
    Ok(_) -> Nil
    Error(err) -> panic as snag.pretty_print(err)
  }
}

fn describe_sqlite_error(err: sqlight.Error) -> String {
  err.message
  <> " (code: "
  <> err.code |> sqlight.error_code_to_int |> int.to_string
  <> ") "
}
