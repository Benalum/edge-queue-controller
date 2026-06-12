# Stage 6AC Universal Intent Router Seed Data Module

Stage 6AC adds initial seed data for the Universal Intent Router foundation.

This stage does not change runtime behavior.

This stage does not wire router dispatch.

This stage does not call models.

This stage does not modify frontend behavior.

## Why this stage exists

Stage 6AA added the router schema module.

Stage 6AB wired the schema into controller SQLite initialization.

The router tables now exist, but they are empty.

Stage 6AC creates a safe idempotent seed module for:

- intent definitions
- intent routes
- global phrase bank entries

## New module

`edge_router_seed.py`

The module provides:

- `seed_router_foundation_data(conn)`
- `router_seed_counts(conn)`

## Seeded intent groups

Initial seed data includes:

- Study session intents
- Study card intents
- Companion chat intent
- Chat message intent
- Calendar event/reminder draft intents
- Unknown unsupported fallback intent

## Seeded phrase groups

Initial global phrase bank entries include:

- English Study navigation phrases
- English Study answer phrases
- English Study scoring phrases
- Spanish Study aliases

## Safety boundary

The seed module only inserts configuration data.

It does not execute actions.

It does not dispatch to Study.

It does not dispatch to Companion.

It does not dispatch to Chat.

It does not dispatch to Calendar.

It does not call an LLM.

It does not enable the router endpoint.

## Future stage

A later stage should wire this seed module into controller initialization or apply it directly to the live SQLite database after a backup.

## Stage 6AC acceptance criteria

Stage 6AC is complete when:

- `edge_router_seed.py` exists.
- The module compiles.
- A temporary SQLite DB can initialize router schema and seed data.
- Seed counts are nonzero for intent definitions, intent routes, and global phrases.
- Study, Companion, Chat, Calendar, Profile, Admin, queue, worker, frontend, and power behavior remain unchanged.
