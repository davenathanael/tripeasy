dev:
    watchexec --restart --wrap-process=session --exts gleam --watch src/ -- "gleam run"



db-reset:
    dbmate drop
    dbmate up

db-up:
    dbmate up

db-new *args:
    dbmate --migrations-dir ./priv/db/migrations new {{args}}

db +args:
    if args == "reset"; then \
        dbmate --migrations-dir ./priv/db/migrations drop; \
        dbmate --migrations-dir ./priv/db/migrations up; \
    else \
        dbmate --migrations-dir ./priv/db/migrations {{args}}; \
    fi
