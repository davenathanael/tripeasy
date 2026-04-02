import gleam/option
import gleam/time/timestamp
import paket/oauth
import sqlight
import tripeasy/core
import tripeasy/db
import tripeasy/sql

pub type SessionStatus {
  Authenticating
  Authenticated
}

pub type SessionDetails {
  SessionDetails(
    id: String,
    status: SessionStatus,
    state: option.Option(String),
    user_id: option.Option(core.Id),
    created_at: timestamp.Timestamp,
    expired_at: timestamp.Timestamp,
  )
}

pub fn sqlite_session_storage(
  conn: sqlight.Connection,
) -> oauth.SessionStorage(SessionDetails) {
  let read = fn(id) {
    let a = sql.get_session(id) |> db.query_with(conn)
  }

  oauth.SessionStorage(read:, store: todo, delete: todo)
}

fn map_to_session_details(row: sql.UpsertSession) -> Result(SessionDetails, Nil) {
  let sql.UpsertSession(
    id:,
    status:,
    state:,
    user_id:,
    expired_at:,
    created_at:,
    updated_at: _,
  ) = row
  let user_id = case user_id {
    option.Some(id) -> id |> core.parse_id |> option.from_result
    _ -> option.None
  }

  case status {
    "authenticating" ->
      SessionDetails(
        id:,
        status: Authenticating,
        state:,
        user_id:,
        expired_at:,
        created_at:,
      )
      |> Ok
    "authenticated" ->
      SessionDetails(
        id:,
        status: Authenticated,
        state:,
        user_id:,
        expired_at:,
        created_at:,
      )
      |> Ok
    _ -> Error(Nil)
  }
}
