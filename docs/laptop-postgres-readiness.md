# Laptop Postgres Readiness — Stage 5D-1

## Purpose

Stage 5D-1 records the current laptop database readiness before adding the future laptop-owned source-of-truth database.

This stage is documentation and smoke checks only.

No Postgres installation, schema creation, service changes, or data migration happens in this stage.

## Current finding

The laptop/controller does not currently have Postgres installed or running.

Observed readiness output:

- postgresql.service was not found
- psql was not installed
- postgres system user did not exist

The current controller data store is SQLite:

- edge_queue.sqlite3

## Current controller database role

The current SQLite database remains the active controller database for now.

It currently supports controller/runtime features such as:

- power automation state
- worker/controller metadata
- public wrapper/controller auth and credit-related state
- local smoke-test databases

## Target future database

The future laptop-owned source-of-truth database should be a dedicated local Postgres database.

Recommended target:

- database name: ai_platform_controller
- database user: ai_platform_controller
- host: localhost
- owner: laptop/controller
- purpose: source-of-truth app/controller database

## Why not use CT101 Postgres as final owner

CT101 Postgres should not be the final source of truth because CT101 may be powered off.

The target architecture requires users to be able to:

- log in while CT101 is offline
- view saved data while CT101 is offline
- create study/chat/calendar data while CT101 is offline
- queue jobs while CT101 is offline
- see pending/offline/booting status from the laptop wrapper

That requires source-of-truth data to live on the always-on laptop/controller.

## Recommended future setup

Laptop/controller should eventually own:

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
- power/system status

CT101 should eventually own only:

- worker runtime
- model execution
- Ollama/model files
- temporary execution scratch/cache

## Required before any migration

Before moving any CT101 data to laptop Postgres:

1. Install and verify laptop Postgres.
2. Create a dedicated database and user.
3. Add backup script.
4. Add restore script.
5. Add smoke check for backup freshness.
6. Add schema foundation.
7. Add read-only comparison/export checks from CT101.
8. Create rollback instructions.
9. Migrate one domain at a time.

## Recommended next stages

### Stage 5D-2

Install/setup local Postgres on the laptop/controller.

### Stage 5D-3

Add backup and restore scripts before production data is moved.

### Stage 5D-4

Add initial empty laptop app schema.

### Stage 5E

Begin job queue facade migration, because queued work benefits most from laptop ownership.

## Stage 5D-1 constraints

Do not:

- install Postgres
- create schemas
- migrate data
- modify CT101
- restart services
- change live runtime behavior
- change power automation
