import envoy
import gleam/int
import gleam/result
import snag
import tripeasy/utils

pub type Config {
  Config(
    secret_key_base: String,
    port: Int,
    database_url: String,
    priv_static_directory: String,
    static_path: String,
  )
}

pub fn load() -> snag.Result(Config) {
  use _ <- result.try(utils.load_env_file(".env"))

  use secret_key_base <- result.try(
    envoy.get("SECRET_KEY_BASE")
    |> snag.replace_error("Unable to load SECRET_KEY_BASE"),
  )

  use port <- result.try(
    envoy.get("PORT")
    |> snag.replace_error("Unable to load PORT"),
  )
  use port <- result.try(
    int.parse(port)
    |> snag.replace_error("Unable to parse PORT"),
  )

  use database_url <- result.try(
    envoy.get("DATABASE_URL")
    |> snag.replace_error("Unable to load DATABASE_URL"),
  )

  let priv_static_directory = "priv/static"
  let static_path = "/static"

  Ok(Config(
    secret_key_base:,
    port:,
    database_url:,
    priv_static_directory:,
    static_path:,
  ))
}
