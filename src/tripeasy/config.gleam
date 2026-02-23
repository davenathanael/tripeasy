import envoy
import gleam/int
import gleam/result

pub type Config {
  Config(secret_key_base: String, port: Int, database_url: String)
}

pub fn load() -> Result(Config, String) {
  use secret_key_base <- result.try(
    envoy.get("SECRET_KEY_BASE")
    |> result.replace_error("Unable to load SECRET_KEY_BASE"),
  )

  use port <- result.try(
    envoy.get("PORT")
    |> result.replace_error("Unable to load PORT"),
  )
  use port <- result.try(
    int.parse(port)
    |> result.replace_error("Unable to parse PORT"),
  )

  use database_url <- result.try(
    envoy.get("DATABASE_URL")
    |> result.replace_error("Unable to load DATABASE_URL"),
  )

  Ok(Config(secret_key_base:, port:, database_url:))
}
