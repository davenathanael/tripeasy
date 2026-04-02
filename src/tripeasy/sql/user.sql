-- name: GetSession :one

select * from session_details
where id = ?
and expired_at > current_timestamp;

-- name: UpsertSession :one
insert into session_details (id, status, state, user_id, expired_at)
values (?, ?, ?, ?, ?)
on conflict (id) do update
set status = excluded.status,
    state = excluded.state,
    user_id = excluded.user_id,
    expired_at = excluded.expired_at
returning *;

-- name: GetUser :one
select * from users where id = ?;
