import envoy
import gleam/list
import gleam/result
import gleam/string
import simplifile
import snag

pub fn must(res: snag.Result(a)) -> a {
  case res {
    Ok(value) -> value
    Error(err) -> panic as snag.pretty_print(err)
  }
}

pub fn is_non_empty_string(s: String) -> Bool {
  s != ""
}

pub fn load_env_file(path: String) -> snag.Result(Nil) {
  use lines <- result.try(
    simplifile.read(from: path)
    |> snag.map_error(simplifile.describe_error)
    |> snag.context("unable to load env file: " <> path),
  )

  lines
  |> string.split("\n")
  |> list.map(string.trim)
  |> list.filter(is_non_empty_string)
  |> list.map(fn(line) {
    let parts = line |> string.trim |> string.split_once("=")

    case parts {
      Ok(#(key, value)) -> envoy.set(key, value) |> Ok
      Error(_) -> Error("Unable to read line: " <> line)
    }
  })
  |> result.all
  |> result.replace(Nil)
  |> result.map_error(snag.new)
}
