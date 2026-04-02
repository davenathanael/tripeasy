import gleam/dynamic/decode
import gleam/int
import gleam/list
import gleam/result
import parrot/dev
import snag
import sqlight

pub type DatabaseError {
  NoResult
  SqlightError(sqlight.Error)
}

pub fn query_with(
  query query: #(String, List(dev.Param), decode.Decoder(row)),
  conn conn: sqlight.Connection,
) -> Result(List(row), sqlight.Error) {
  let #(sql, with, expecting) = query
  let with = with |> list.map(parrot_to_sqlight)
  sqlight.query(sql, on: conn, with:, expecting:)
}

pub fn get_one(
  query_result: Result(List(row), sqlight.Error),
) -> Result(row, DatabaseError) {
  case query_result {
    Ok([first, ..]) -> Ok(first)
    Ok([]) -> Error(NoResult)
    Error(err) -> Error(SqlightError(err))
  }
}

pub fn get_many(
  query_result: Result(List(row), sqlight.Error),
) -> Result(List(row), DatabaseError) {
  case query_result {
    Ok([]) -> Error(NoResult)
    Ok(rows) -> Ok(rows)
    Error(err) -> Error(SqlightError(err))
  }
}

pub fn get_any(
  query_result: Result(List(row), sqlight.Error),
) -> Result(List(row), DatabaseError) {
  case query_result {
    Ok(rows) -> Ok(rows)
    Error(err) -> Error(SqlightError(err))
  }
}

pub fn with_connection(
  database_url: String,
  run: fn(sqlight.Connection) -> Nil,
) -> Nil {
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

pub fn describe_error(err: DatabaseError) -> String {
  case err {
    NoResult -> "no result found"
    SqlightError(err) -> describe_sqlite_error(err)
  }
}

fn describe_sqlite_error(err: sqlight.Error) -> String {
  err.message
  <> " (code: "
  <> err.code |> sqlight.error_code_to_int |> int.to_string
  <> ") "
}

fn parrot_to_sqlight(param: dev.Param) -> sqlight.Value {
  case param {
    dev.ParamFloat(x) -> sqlight.float(x)
    dev.ParamInt(x) -> sqlight.int(x)
    dev.ParamString(x) -> sqlight.text(x)
    dev.ParamBitArray(x) -> sqlight.blob(x)
    dev.ParamNullable(x) -> sqlight.nullable(fn(a) { parrot_to_sqlight(a) }, x)
    dev.ParamList(_) -> panic as "sqlite does not implement lists"
    dev.ParamBool(_) -> panic as "sqlite does not support booleans"
    dev.ParamDate(_) -> panic as "sqlite does not support dates"
    dev.ParamTimestamp(_) -> panic as "sqlite does not support timestamps"
    dev.ParamDynamic(_) -> todo
  }
}
