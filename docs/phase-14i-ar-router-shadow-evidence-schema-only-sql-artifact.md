# Phase 14I-AR Router Shadow Evidence Schema-Only SQL Artifact

Phase 14I-AR adds the future schema-only SQL artifact for queued-chat router shadow evidence.

This phase adds:

- `ops/db/laptop-app-schema-v3-router-shadow-evidence.sql`
- a docs record,
- a static smoke.

This phase does not apply a database migration.
This phase does not call `psql`.
This phase does not source database environment files.
This phase does not add a writer.
This phase does not change runtime behavior.
This phase does not expose router shadow output to the browser.
This phase does not persist router shadow evidence at runtime.
This phase does not enable router model selection.
This phase does not mutate CT101.
This phase does not call live model endpoints.

## Current Verified Starting Point

Phase 14I-AQ completed the SQL artifact preflight plan.

The current runtime contract remains unchanged:

- `/api/chat/queued` calls `_phase14iag_queued_chat_router_shadow_decision(guard_payload)`.
- `EDGE_QUEUED_CHAT_ROUTER_SHADOW_ENABLED` remains default-off.
- The shadow helper return value is discarded.
- Live `requested_model` pass-through remains unchanged.
- No router shadow output is returned to the browser.
- No router shadow evidence is persisted by runtime code.
- No writer exists for router shadow evidence.

## SQL Artifact Added

The schema-only artifact is:

`ops/db/laptop-app-schema-v3-router-shadow-evidence.sql`

The artifact follows the existing controller-owned `ops/db/laptop-app-schema-v*.sql` family.

It includes:

- explicit transaction boundaries,
- additive table creation,
- narrow indexes,
- an `app_schema_migrations` marker,
- no writer,
- no route changes,
- no runtime hook changes.

## Table Name

`queued_chat_router_shadow_evidence`

## Migration Marker

`stage-14i-router-shadow-evidence`

## Controller-Owned Boundary

The table is intended for the trusted controller/backend persistence boundary.

It is not a CT101 table.

It is not browser-owned state.

It is not external-node state.

It is not model-owned state.

## Privacy Boundary

The SQL artifact avoids columns for:

- user message text,
- prompt text,
- context text,
- request body text,
- queue summary text,
- cookie values,
- auth header values,
- bearer token values,
- session token values,
- secret values,
- full payload blobs,
- full router traces,
- full model responses.

Only bounded operational metadata is represented.

## Writer Separation Rule

This phase does not add a writer.

A future writer helper must remain a separate phase after this SQL artifact is reviewed and validated.

The future writer must be default-off and must never block queued-chat job creation.

## Apply Separation Rule

This phase does not apply the SQL artifact.

A later apply phase must be explicitly gated and must include backup, rollback, restore, and verification steps.

## Prior Smoke Note

Some earlier planning smokes intentionally asserted that this SQL file did not exist yet.

After Phase 14I-AR, those older pre-artifact smokes are superseded for that specific assertion.

Use the Phase 14I-AR smoke as the current validation authority for this artifact state.

## Phase 14I-AR Validation Scope

This phase validates only that:

- this document exists,
- the SQL artifact exists,
- the SQL artifact follows expected schema-only markers,
- runtime code still compiles,
- changed files are limited to this SQL/docs/smoke phase,
- no runtime writer marker is introduced,
- no route behavior is changed,
- no browser exposure is introduced,
- no CT101 mutation path is introduced,
- no database apply command is executed.

## Exit Criteria

Phase 14I-AR is complete when:

- the SQL artifact exists,
- this document exists,
- its static smoke exists,
- the smoke passes,
- `edge_controller.py` still compiles,
- git diff contains only this SQL/docs/smoke phase,
- the phase is committed, tagged, and pushed.

After Phase 14I-AR, the next safe follow-up should be an apply-readiness gate for the SQL artifact, still without applying it unless explicitly approved.
