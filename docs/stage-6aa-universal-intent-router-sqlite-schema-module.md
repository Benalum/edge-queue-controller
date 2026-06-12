# Stage 6AA Universal Intent Router SQLite Schema Module

Stage 6AA adds the Universal Intent Router SQLite schema module.

This stage does not change runtime behavior.

This stage does not wire the schema into `edge_controller.py`.

This stage does not modify Study, Companion, Chat, Calendar, Profile, Admin, auth, queue, worker, power automation, frontend behavior, or systemd behavior.

## Why this stage exists

The repository already has a Universal Intent Router dry-run foundation through Stage 6Z.

The current missing foundation is persistent router storage.

The local SQLite database currently has app, study, session, worker, power, support, credit, and calendar tables, but no router-specific persistent tables.

Stage 6AA creates the table definitions in a standalone module first so they can be tested safely before runtime wiring.

## New module

`edge_router_schema.py`

The module provides:

- `init_router_foundation_schema(conn)`
- `router_foundation_table_names()`

## Router tables

The schema defines:

- `intent_definitions`
- `intent_routes`
- `global_phrase_bank`
- `user_phrase_bank`
- `user_language_preferences`
- `user_secondary_languages`
- `router_logs`
- `router_resolution_steps`
- `router_feedback`

## Design rules

The schema is additive.

The schema uses SQLite-compatible DDL.

The schema does not drop existing tables.

The schema does not alter existing app tables.

The schema is not automatically applied to the production database in this stage.

## Future wiring

A later stage should explicitly wire `init_router_foundation_schema(conn)` into the controller database initialization path.

That future stage should:

1. Back up `edge_queue.sqlite3`.
2. Add the schema initialization call.
3. Restart the controller.
4. Verify the new tables exist.
5. Confirm the router dry-run endpoint remains disabled by default.
6. Confirm Study, Companion, Chat, Profile, Admin, power, and queue behavior are unchanged.

## Stage 6AA acceptance criteria

Stage 6AA is complete when:

- `edge_router_schema.py` exists.
- The module compiles.
- A temporary SQLite database can initialize the router tables.
- All required router tables exist in the temporary database.
- The smoke verifies the schema is not wired into runtime yet.
- No runtime behavior changes.
