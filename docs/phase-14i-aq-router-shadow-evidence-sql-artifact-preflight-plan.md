# Phase 14I-AQ Router Shadow Evidence SQL Artifact Preflight Plan

Phase 14I-AQ records the preflight rules for a future schema-only SQL artifact for queued-chat router shadow evidence.

This phase is documentation and static smoke validation only.

It does not apply a database migration.
It does not add a SQL artifact.
It does not add a migration file.
It does not add executable schema code.
It does not add a writer.
It does not change runtime behavior.
It does not expose router shadow output to the browser.
It does not persist router shadow evidence.
It does not enable router model selection.
It does not mutate CT101.
It does not call live model endpoints.

## Current Verified Starting Point

Phase 14I-AP drafted the future schema-only migration plan.

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

This phase prepares the rules a later phase must follow before creating a schema-only SQL artifact.

The next SQL artifact must be narrow, additive, idempotent, controller-owned, privacy-preserving, and independent from writer activation.

## Existing SQL Style to Follow

Existing controller-owned SQL surfaces use:

- explicit transaction boundaries,
- additive schema changes,
- idempotent operations where possible,
- `app_schema_migrations` version recording,
- comments explaining safety and runtime impact.

The future SQL artifact should follow the existing `ops/db/laptop-app-schema-v*.sql` family.

Candidate future file:

`ops/db/laptop-app-schema-v3-router-shadow-evidence.sql`

This phase does not create that file.

## Future SQL Artifact Preflight Requirements

A later SQL artifact phase must verify:

1. The repo is clean.
2. The latest pushed checkpoint is known.
3. The migration target remains controller-owned.
4. The future SQL file name does not already exist.
5. Backup and restore scripts exist.
6. The SQL artifact is schema-only.
7. The SQL artifact has no writer logic.
8. The SQL artifact has no route logic.
9. The SQL artifact has no model call logic.
10. The SQL artifact has no browser output logic.
11. The SQL artifact records a migration version marker.
12. The SQL artifact avoids raw prompt, raw request, raw context, and raw payload storage.

## Future SQL Artifact Allowed Shape

A later schema-only SQL artifact may contain:

- comments,
- transaction begin and commit,
- a narrow create-table statement for `queued_chat_router_shadow_evidence`,
- narrow indexes,
- an `app_schema_migrations` marker insert,
- idempotency guards supported by the existing database style.

This phase does not add those statements.

## Future SQL Artifact Blocked Shape

A later SQL artifact must not contain:

- raw prompt columns,
- raw message columns,
- raw context columns,
- raw request body columns,
- raw queue summary columns,
- cookie columns,
- auth header columns,
- bearer token columns,
- session token columns,
- secret columns,
- full payload blob columns,
- full router trace columns,
- full model response columns,
- trigger-based writer behavior,
- route behavior changes,
- scheduler behavior changes.

## Candidate Future Table Name

`queued_chat_router_shadow_evidence`

This phase does not create the table.

## Candidate Future Migration Marker

`stage-14i-router-shadow-evidence`

This phase does not insert the marker.

## Candidate Future Safety Columns

A later SQL artifact may include bounded metadata columns for:

- creation time,
- related job id,
- request surface,
- router policy version,
- decision status,
- candidate route key,
- candidate model tier,
- candidate model family,
- confidence bucket or bounded confidence value,
- escalation reason code,
- fallback reason code,
- live requested model,
- live path preserved flag,
- browser exposed flag,
- route behavior changed flag,
- safe allowlist version,
- rejected unsafe field count,
- redaction count,
- writer gate name,
- writer gate enabled flag.

The future SQL artifact must keep all fields bounded and non-secret-bearing.

## Future Writer Separation Rule

A SQL artifact phase must not add a writer.

A writer helper must remain a separate later phase after the schema artifact is reviewed, committed, pushed, and validated.

The future writer must be default-off and must never block queued-chat job creation.

## Future Apply Separation Rule

Creating a SQL artifact and applying it may be separated if safety requires it.

If a later phase applies the SQL artifact, it must explicitly gate the apply step and include backup, rollback, restore, and verification output.

## Phase 14I-AQ Validation Scope

This phase validates only that:

- this SQL artifact preflight plan exists,
- the scope remains docs/smoke only,
- runtime code still compiles,
- existing SQL migration style files are present,
- no SQL artifact is added,
- no migration file is added,
- no executable schema code is added,
- no writer marker is added outside docs/smoke,
- no router model selection is enabled,
- no browser exposure marker is introduced,
- no CT101 mutation path is introduced.

## Exit Criteria

Phase 14I-AQ is complete when:

- this document exists,
- its static smoke exists,
- the smoke passes,
- `edge_controller.py` still compiles,
- git diff contains only this docs/smoke phase,
- the phase is committed, tagged, and pushed.

After Phase 14I-AQ, the next safe follow-up can be a gated schema-only SQL artifact creation phase, still without applying the migration and still without adding a writer.
