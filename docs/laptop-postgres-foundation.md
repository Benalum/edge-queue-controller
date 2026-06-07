# Laptop Postgres Foundation — Stage 5D-2

## Purpose

Stage 5D-2 creates the local laptop/controller Postgres foundation for the future laptop-owned source-of-truth database.

This stage creates the database and role only.

It does not migrate CT101 data.

## Created local database

Local database:

- database name: ai_platform_controller
- database user: ai_platform_controller
- host: 127.0.0.1
- port: 5432
- owner: laptop/controller

## Verification result

The laptop Postgres foundation was verified with:

- postgresql service active
- ai_platform_controller role reachable
- ai_platform_controller database reachable
- current_database returned ai_platform_controller
- current_user returned ai_platform_controller

## Local secret storage

The local connection string is stored outside the repository:

- ~/.config/ai-platform-controller/postgres.env

This file must not be committed.

It contains:

- DATABASE_URL
- PGDATABASE
- PGUSER
- PGHOST
- PGPORT

## Current role

The new database is a foundation only.

The active controller runtime still uses the existing SQLite database for now:

- edge_queue.sqlite3

## Future role

The new Postgres database will eventually become source of truth for:

- users
- sessions
- profiles
- chats
- messages
- study decks/cards/reviews
- calendar events
- durable jobs
- worker registry/status
- credits/account state
- power/system state if consolidated

## Required before data migration

Before any production data moves into this Postgres database:

1. Add backup script.
2. Add restore script.
3. Add backup freshness smoke.
4. Add initial schema foundation.
5. Add read-only export checks from CT101.
6. Add rollback instructions.
7. Migrate one domain at a time.

## Stage 5D-2 constraints

Do not:

- migrate CT101 data
- change CT101 schemas
- change controller runtime database source
- move auth source of truth yet
- change worker behavior
- change power automation
- commit database credentials
