import envoy
import gleam/int
import gleam/list
import gleam/result
import gleam/string
import simplifile

pub type Config {
  Config(secret_key_base: String, port: Int, database_url: String)
}

pub fn load() -> Result(Config, String) {
  use _ <- result.try(load_env_file(".env"))

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

fn load_env_file(path: String) -> Result(Nil, String) {
  use lines <- result.try(
    simplifile.read(from: path)
    |> result.map_error(fn(err) {
      "Unable to load .env file: " <> simplifile.describe_error(err)
    }),
  )

  lines
  |> string.split("\n")
  |> list.map(fn(line) {
    let line = string.trim(line)
    case
      line
      |> string.split_once("=")
    {
      Ok(#(key, value)) -> envoy.set(key, value) |> Ok
      Error(_) -> Error("Unable to load env: " <> line)
    }
  })
  |> result.all
  |> result.replace(Nil)
}
