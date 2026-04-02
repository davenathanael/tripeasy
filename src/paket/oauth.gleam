import flwr_oauth2 as oauth2
import flwr_oauth2/pkce
import gleam/dynamic/decode
import gleam/http
import gleam/http/request
import gleam/httpc
import gleam/json
import gleam/option
import gleam/result
import gleam/uri
import wisp

const oidc_discovery_endpoint = ".well-known/openid-configuration"

const session_name = "paket_session_id"

pub type SessionId {
  SessionId(String)
}

pub type Session(user) {
  NoSession
  Authenticating(state: String)
  Authenticated(id: SessionId, user: user)
}

type DiscoveryData {
  DiscoveryData(authorization_endpoint: uri.Uri, token_endpoint: uri.Uri)
}

pub type AuthError {
  UnknownError
  ConfigurationError(String)
  RequestError(httpc.HttpError)
  ResponseError(json.DecodeError)
}

pub type SessionStorageError {
  SessionNotFound
  InternalError(String)
}

pub type SessionStorage(session_user) {
  SessionStorage(
    read: fn(SessionId) -> Result(Session(session_user), SessionStorageError),
    store: fn(SessionId, Session(session_user)) ->
      Result(Nil, SessionStorageError),
    delete: fn(SessionId) -> Result(Nil, SessionStorageError),
  )
}

pub type AuthConfig(session_user) {
  AuthConfig(
    client_id: String,
    discovery_url: uri.Uri,
    authorization_url: uri.Uri,
    token_url: uri.Uri,
    redirect_url: uri.Uri,
    storage: SessionStorage(session_user),
  )
}

// Functions

pub fn is_authenticated(session: Session(session_user)) -> Bool {
  case session {
    NoSession -> False
    Authenticating(_) -> False
    Authenticated(_, _) -> True
  }
}

pub fn configure(
  client_id: String,
  storage: SessionStorage(session_user),
  oidc_server_url: String,
  app_base_url: String,
  callback_path: String,
) -> Result(AuthConfig(session_user), AuthError) {
  use discovery_url <- result.try(
    merge_uris(oidc_server_url, oidc_discovery_endpoint)
    |> result.map_error(ConfigurationError),
  )

  use redirect_url <- result.try(
    merge_uris(app_base_url, callback_path)
    |> result.map_error(ConfigurationError),
  )

  use req <- result.try(
    request.from_uri(discovery_url)
    |> result.replace_error(ConfigurationError(
      "unable to create request from discovery_url",
    )),
  )

  use res <- result.try(
    httpc.send(req)
    |> result.map_error(RequestError),
  )

  use
    DiscoveryData(
      authorization_endpoint: authorization_url,
      token_endpoint: token_url,
    )
  <- result.try(
    json.parse(res.body, discovery_data_decoder())
    |> result.map_error(ResponseError),
  )

  Ok(AuthConfig(
    client_id:,
    discovery_url:,
    authorization_url:,
    token_url:,
    redirect_url:,
    storage:,
  ))
}

// Middleware

pub fn session_middleware(
  req: wisp.Request,
  config: AuthConfig(session_user),
  next: fn(Session(session_user)) -> wisp.Response,
) {
  let session =
    wisp.get_cookie(req, session_name, wisp.Signed)
    |> result.try(fn(id) {
      // TODO: handle error
      config.storage.read(SessionId(id)) |> result.replace_error(Nil)
    })
    |> result.unwrap(NoSession)

  next(session)
}

// Wisp request handlers

pub fn login_handler(
  req: wisp.Request,
  config: AuthConfig(session_user),
) -> wisp.Response {
  use <- wisp.require_method(req, http.Post)

  let session_id = oauth2.random_state32().value
  let state = oauth2.random_state32()
  let code_verifier = pkce.new()
  let code_challenge = code_verifier |> pkce.to_challenge

  let _ =
    config.storage.store(SessionId(session_id), Authenticating(state.value))

  let redirect_uri =
    oauth2.make_redirect_uri(oauth2.AuthorizationCodeGrantRedirectUriWithPKCE(
      oauth_server: config.authorization_url,
      response_type: oauth2.Code,
      redirect_uri: option.Some(config.redirect_url),
      client_id: config.client_id |> oauth2.ClientId,
      scope: ["openid", "profile"],
      state: option.Some(state),
      code_challenge: code_challenge.value,
      code_challenge_method: oauth2.S256,
    ))

  redirect_uri
  |> uri.to_string()
  |> wisp.redirect()
  |> wisp.set_cookie(req, session_name, session_id, wisp.Signed, 60 * 60 * 24)
}

// Helpers

fn merge_uris(base: String, relative: String) -> Result(uri.Uri, String) {
  use base_uri <- result.try(
    uri.parse(base)
    |> result.replace_error("unable to parse base uri: " <> base),
  )

  use relative_uri <- result.try(
    uri.parse(relative)
    |> result.replace_error("unable to parse relative uri: " <> relative),
  )

  uri.merge(base_uri, relative_uri)
  |> result.replace_error("unable to merge base and relative uris")
}

// Decoders

fn discovery_data_decoder() -> decode.Decoder(DiscoveryData) {
  use authorization_endpoint <- decode.field(
    "authorization_endpoint",
    uri_decoder(),
  )
  use token_endpoint <- decode.field("token_endpoint", uri_decoder())
  decode.success(DiscoveryData(authorization_endpoint:, token_endpoint:))
}

fn uri_decoder() -> decode.Decoder(uri.Uri) {
  use str <- decode.then(decode.string)
  case uri.parse(str) {
    Ok(value) -> decode.success(value)
    Error(_) -> decode.failure(uri.empty, "Uri")
  }
}
// In-memory session storage

// pub fn in_memory_storage() -> SessionStorage(String) {
//   let sessions: dict.Dict(SessionId, #(String, String)) = dict.new()

//   let read = fn(id: SessionId) -> Result(Session(String), SessionStorageError) {
//     case dict.get(sessions, id) {
//       Ok(#("authenticating", state)) -> Ok(Authenticating(state))
//       Ok(#("authenticated", user)) -> Ok(Authenticated(id, user))
//       _ -> Error(SessionNotFound)
//     }
//   }

//   let delete = fn(id) {
//     dict.delete(sessions, id)
//     |> Ok
//   }

//   let store = fn(id, user) {
//     dict.insert(sessions, id, user)
//     |> Ok
//   }

//   SessionStorage(
//     read: fn(id) {
//       case dict.get(sessions, id) {
//         Ok(#("authenticating", state)) -> Ok(Authenticating(state))
//         Ok(#("authenticated", user)) -> Ok(Authenticated(id, user))
//         _ -> Error(SessionNotFound)
//       }
//     },
//     delete: fn(id) {
//       dict.delete(sessions, id)
//       |> Ok
//     },
//     store:,
//   )
// }
