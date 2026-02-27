import sqlight.{type Connection}
import tripeasy/config.{type Config}

pub type Context {
  Context(config: Config, db: Connection)
}
