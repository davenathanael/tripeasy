CREATE TABLE IF NOT EXISTS "schema_migrations" (version varchar(128) primary key);
CREATE TABLE users (
  id text primary key,
  name text,
  email text unique not null,
  avatar_url text,
  created_at timestamp not null default current_timestamp,
  updated_at timestamp not null default current_timestamp
);
CREATE TABLE session_details (
    id text primary key,
    status text not null,
    user_id text not null,
    expired_at timestamp not null,
    created_at timestamp not null default current_timestamp,
    updated_at timestamp not null default current_timestamp
);
-- Dbmate schema migrations
INSERT INTO "schema_migrations" (version) VALUES
  ('20260302123340');
