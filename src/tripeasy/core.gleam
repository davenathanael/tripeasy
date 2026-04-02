import gleam/option.{type Option}
import gleam/result
import youid/uuid

///
/// Core Types
///
pub opaque type Id {
  Id(String)
}

pub type Url =
  String

pub type Email =
  String

pub type OAuthSocial {
  Google
  Facebook
  Twitter
}

pub type AuthMethod {
  EmailPassword
  Passkey
  Social(OAuthSocial)
}

pub type UserAuthDetails {
  UserAuthDetails(identity_id: String, method: AuthMethod)
}

pub type UserProfile {
  UserProfile(name: String, email: Email, avatar_url: Option(String))
}

pub type User {
  NormalUser(
    id: Id,
    primary_email: Email,
    // FUTURE: room for multiple profiles
    profile: UserProfile,
    // FUTURE: room for multiple auth methods/links
    auth: UserAuthDetails,
  )
  Admin(
    id: Id,
    primary_email: Email,
    profile: UserProfile,
    auth: UserAuthDetails,
  )
}

pub type Location {
  Location(
    id: Id,
    name: String,
    description: Option(String),
    latlong: #(Float, Float),
    map_url: Option(Url),
  )
}

pub type Trip {
  Trip(
    id: Id,
    name: String,
    description: Option(String),
    locations: List(Location),
    members: List(TripMember),
  )
}

pub type TripMember {
  TripMember(user: User, role: TripMemberRole)
}

pub type TripMemberRole {
  Owner
  Editor
  Viewer
}

// Operations

/// Generates a new unique identifier. The underlying implementation uses the UUID v7 algorithm converted as string.
pub fn new_id() -> Id {
  Id(uuid.v7_string())
}

pub fn new_user(
  name: String,
  email: String,
  avatar_url: Option(String),
  identity_id: String,
  method: AuthMethod,
) -> User {
  NormalUser(
    new_id(),
    email,
    UserProfile(name:, email:, avatar_url:),
    UserAuthDetails(identity_id:, method:),
  )
}

pub fn new_trip(name: String, description: Option(String), owner: User) -> Trip {
  let locations = []
  let members = [TripMember(owner, Owner)]
  Trip(new_id(), name:, description:, locations:, members:)
}

pub fn parse_id(str: String) -> Result(Id, String) {
  use id <- result.try(
    uuid.from_string(str) |> result.replace_error("string is not an uuid"),
  )

  case uuid.version(id) {
    uuid.V7 -> Ok(Id(str))
    _ -> Error("uuid is not v7")
  }
}
