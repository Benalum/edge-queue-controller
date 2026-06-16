# Phase 14I-AN Router Shadow Evidence Migration Mechanism Inspection

Phase 14I-AN records a static inspection plan for the repository migration mechanism before any future schema-only migration for router shadow evidence.

This phase is documentation and static smoke validation only.

It does not apply a database migration.
It does not add a migration file.
It does not add SQL.
It does not add a writer.
It does not change runtime behavior.
It does not expose router shadow output to the browser.
It does not persist router shadow evidence.
It does not enable router model selection.
It does not mutate CT101.
It does not call live model endpoints.

## Current Verified Starting Point

Phase 14I-AM completed the migration readiness plan for the future `queued_chat_router_shadow_evidence` surface.

The current runtime contract remains unchanged:

- `/api/chat/queued` calls `_phase14iag_queued_chat_router_shadow_decision(guard_payload)`.
- `EDGE_QUEUED_CHAT_ROUTER_SHADOW_ENABLED` remains default-off.
- The shadow helper return value is discarded.
- Live `requested_model` pass-through remains unchanged.
- No router shadow output is returned to the browser.
- No router shadow evidence is persisted.
- No database migration exists for router shadow evidence.
- No writer exists for router shadow evidence.

## Purpose of This Phase

Before a later phase can safely prepare a schema-only migration plan, the project must identify the correct migration mechanism and ownership boundary.

This phase does not choose to apply a migration. It records the inspection criteria and prevents accidental drift into runtime implementation.

## Migration Mechanism Questions

A later schema-only phase must answer these questions before writing or applying any schema artifact:

1. What is the authoritative database for controller-owned queue evidence?
2. Does this repository use inline startup schema creation, migration files, SQL scripts, Alembic-style migrations, or another existing mechanism?
3. Where are current queue tables defined or evolved?
4. What validation already exists for schema safety?
5. What backup and rollback process applies before schema changes?
6. What is the smallest schema-only artifact that matches the existing repository style?
7. How can the schema exist without any writer, browser output, router activation, or scheduler behavior change?

## Static Inspection Surfaces

The following surfaces may be inspected in later phases without changing runtime behavior:

- `edge_controller.py` schema and queue bootstrap code.
- Existing docs and smokes that mention schema, migration, storage, or persistence.
- Any existing SQL or migration-like files already present in the repository.
- Existing smoke-test patterns for no-persistence and privacy guards.
- Existing database ownership documentation.

Inspection must avoid:

- live database mutation,
- CT101 mutation,
- live model endpoint calls,
- queue payload dumps,
- raw prompt dumps,
- raw request body dumps,
- secret-bearing command output.

## Migration Mechanism Decision Rule

Do not invent a second migration system.

A future schema-only migration plan must follow the repository's existing database evolution style or explicitly document why a new style is required before adding it.

If the current repository has no dedicated migration system, the later plan must stay conservative and separate:

- schema artifact design,
- backup and rollback procedure,
- validation smoke,
- writer helper,
- writer activation,
- router activation.

These must not be combined into one phase.

## Future Schema-Only Migration Boundary

A future schema-only phase may prepare a narrow artifact for `queued_chat_router_shadow_evidence` only after the migration mechanism is confirmed.

That future phase must still avoid:

- writer code,
- persistence calls,
- model calls,
- scheduler changes,
- requested model selection changes,
- browser-visible output,
- backend direct `/jobs` gating,
- Study UI `requested_model` removal,
- legacy fallback removal,
- CT101 mutation,
- job 23 mutation.

## Evidence Privacy Requirements

Any future evidence surface must reject or omit:

- raw user messages,
- raw prompts,
- raw context,
- raw queue summaries,
- raw request bodies,
- cookies,
- auth headers,
- bearer tokens,
- session tokens,
- secrets,
- full payload blobs.

Only bounded allowlisted metadata should be considered.

## Future Follow-Up

The next safe follow-up after this inspection should be a schema-only migration plan or draft artifact inspection.

That follow-up should still be gated, should not apply the migration automatically, and should not add a writer.

## Phase 14I-AN Validation Scope

This phase validates only that:

- this mechanism inspection document exists,
- the scope remains docs/smoke only,
- runtime code still compiles,
- no runtime/schema implementation marker is introduced outside docs/smoke,
- no migration file is added,
- no SQL artifact is added,
- no writer marker is added,
- no router model selection is enabled,
- no browser exposure marker is introduced.

## Exit Criteria

Phase 14I-AN is complete when:

- this document exists,
- its static smoke exists,
- the smoke passes,
- `edge_controller.py` still compiles,
- git diff contains only this docs/smoke phase,
- the phase is committed, tagged, and pushed.
