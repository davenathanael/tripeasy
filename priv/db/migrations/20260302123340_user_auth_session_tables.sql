-- migrate:up
create table if not exists users (
  id text primary key,
  name text,
  email text unique not null,
  avatar_url text,
  created_at timestamp not null default current_timestamp,
  updated_at timestamp not null default current_timestamp
);

create table if not exists session_details (
    id text primary key,
    status text not null,
    state text,
    user_id text,
    expired_at timestamp not null,
    created_at timestamp not null default current_timestamp,
    updated_at timestamp not null default current_timestamp
);

-- migrate:down
drop table if exists session_details;
drop table if exists users;
