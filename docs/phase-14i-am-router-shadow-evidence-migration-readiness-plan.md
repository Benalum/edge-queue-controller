# Phase 14I-AM Router Shadow Evidence Migration Readiness Plan

Phase 14I-AM records migration readiness for the future queued-chat router shadow evidence surface.

This phase is documentation and static smoke validation only.

It does not apply a database migration.
It does not add a migration file.
It does not add a writer.
It does not change runtime behavior.
It does not expose router shadow output to the browser.
It does not persist router shadow evidence.
It does not enable router model selection.

## Current Verified Starting Point

Phase 14I-AL defined the future evidence schema contract for `queued_chat_router_shadow_evidence`.

The current runtime state remains:

- `/api/chat/queued` calls `_phase14iag_queued_chat_router_shadow_decision(guard_payload)`.
- `EDGE_QUEUED_CHAT_ROUTER_SHADOW_ENABLED` remains default-off.
- The helper return value is discarded.
- Live `requested_model` pass-through remains unchanged.
- No browser response includes router shadow output.
- No evidence is persisted.
- No database migration exists.
- No writer exists.

## Readiness Decision

A future migration for `queued_chat_router_shadow_evidence` is not ready to apply yet.

The project is ready only to plan the migration path.

The future evidence surface should remain:

- dedicated,
- narrow,
- append-only,
- privacy-preserving,
- allowlist-based,
- controller-owned,
- non-browser-exposed,
- disabled until explicitly gated.

## Migration Readiness Checklist

Before any later phase applies a schema migration, the following must be true:

1. Confirm the authoritative database target.

   The evidence table must belong to the trusted controller/backend persistence boundary. It must not be introduced into CT101 unless a later explicit gate changes that boundary.

2. Confirm migration mechanism.

   A later phase must identify the existing migration style used by the repository before adding any migration artifact. Do not invent a second migration system.

3. Confirm backup and rollback procedure.

   A later migration phase must document the backup command, rollback plan, and failure recovery path before applying a schema change.

4. Confirm zero raw prompt storage.

   The future table must not store raw user messages, raw prompts, raw context, raw queue summaries, cookies, auth headers, bearer tokens, session tokens, or full request bodies.

5. Confirm strict allowlist.

   Stored evidence may only include bounded metadata needed to compare shadow router decisions safely.

6. Confirm append-only behavior.

   Evidence rows should be append-only. No future writer should mutate existing job payloads or rewrite historical evidence.

7. Confirm job relationship without job mutation.

   A future row may reference a job identifier, but the writer must not archive, delete, mutate, or rewrite job records, including job 23.

8. Confirm no browser exposure.

   No frontend response, public API response, or browser-visible debug field should include router shadow evidence.

9. Confirm default-off writer gate.

   A later writer helper must be behind a new explicit default-off flag and must be separately validated before activation.

10. Confirm retention policy.

   A later phase must define whether evidence is retained indefinitely, pruned by age, or pruned by count. Until then, do not persist evidence.

11. Confirm failure isolation.

   Evidence persistence must never block queued-chat job creation. A future writer failure should be logged safely and skipped, not returned to the user.

12. Confirm lane/router blockers remain respected.

   Persistent lane workers remain inactive, the primary worker remains unfiltered, and router model selection remains parked until later proof supports activation.

## Future Migration Shape

The future migration should be schema-only at first.

Expected future table name:

`queued_chat_router_shadow_evidence`

Expected migration properties:

- create a dedicated table,
- add narrow columns from the Phase 14I-AL schema contract,
- add indexes only for safe operational lookup,
- avoid raw payload blobs,
- avoid raw messages,
- avoid raw request bodies,
- avoid browser-visible output,
- avoid writer code in the same phase.

## Future Writer Shape

A later writer helper may be considered only after the schema migration has been applied and validated.

The future writer must:

- be default-off,
- use a strict field allowlist,
- redact or reject unsafe fields,
- never call a model,
- never enqueue work,
- never alter requested model selection,
- never alter scheduler behavior,
- never expose output to the browser,
- never persist raw prompt/context/message data.

## Not Ready Conditions

Do not apply the migration if any of these are true:

- repository baseline is dirty,
- target database is uncertain,
- rollback plan is missing,
- raw prompt/context storage is proposed,
- writer code is included in the schema phase,
- router model selection is being enabled,
- backend direct `/jobs` gating is being combined with this work,
- Study UI `requested_model` removal is being combined with this work,
- CT101 mutation is required,
- live model endpoint calls are required,
- job 23 would be touched.

## Phase 14I-AM Validation Scope

This phase validates only that:

- this readiness plan exists,
- the scope remains docs/smoke only,
- runtime code still compiles,
- no runtime/schema implementation marker is introduced outside docs/smoke,
- no migration file is added,
- no writer marker is added,
- no router model selection is enabled,
- no browser exposure marker is introduced.

## Exit Criteria

Phase 14I-AM is complete when:

- this document exists,
- its static smoke exists,
- the smoke passes,
- `edge_controller.py` still compiles,
- git diff contains only this docs/smoke phase,
- the phase is committed, tagged, and pushed.

After this phase, the next safe follow-up should still avoid runtime persistence unless a later explicit gate approves a schema-only migration.
