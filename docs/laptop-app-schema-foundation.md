# Laptop App Schema Foundation — Stage 5D-4

## Purpose

Stage 5D-4 creates the first empty laptop/controller Postgres app schema.

This prepares for the future laptop-owned source-of-truth database, but does not migrate CT101 data and does not switch the controller runtime from SQLite.

## Schema file

Schema file:

- ops/db/laptop-app-schema-v1.sql

Apply script:

- ops/db/apply-laptop-app-schema.sh

Smoke check:

- ops/smoke/check-laptop-app-schema.sh

## Tables created

The initial foundation creates:

- app_schema_migrations
- app_users
- app_sessions
- app_chats
- app_messages
- app_jobs
- app_workers
- app_worker_nodes

## Why these tables first

These tables are the core foundation for:

- auth/session source of truth
- chat/message source of truth
- durable job queue
- worker registry/status

Study, calendar, profile, and other domain tables are intentionally postponed.

## Important migration state

No CT101 data is migrated in this stage.

The controller runtime still uses:

- edge_queue.sqlite3

The new Postgres schema is empty foundation only.

## Backup requirement

The apply script runs a laptop Postgres backup before applying the schema.

This follows the Stage 5D-3 rule that backup/restore tooling must exist before schema or data work.

## Future cleanup requirement

After the full migration is complete and verified, a later cleanup stage must remove unused legacy pieces, including:

- unused CT101 frontend pages
- unused CT101 database tables
- unused duplicate API routes
- unused duplicate functions
- obsolete wrapper compatibility pages
- obsolete SQLite tables
- stale smoke tests

Cleanup must not happen until replacements are live, backed up, verified, and rollback-safe.

## Stage 5D-4 constraints

Do not:

- migrate CT101 data
- switch controller runtime to Postgres
- modify CT101
- change auth behavior
- change worker behavior
- change power automation
- remove legacy databases or websites yet
