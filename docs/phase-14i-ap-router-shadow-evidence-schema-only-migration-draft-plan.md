# Phase 14I-AP Router Shadow Evidence Schema-Only Migration Draft Plan

Phase 14I-AP records the future schema-only migration draft plan for queued-chat router shadow evidence.

This phase is documentation and static smoke validation only.

It does not apply a database migration.
It does not add a migration file.
It does not add SQL.
It does not add executable schema code.
It does not add a writer.
It does not change runtime behavior.
It does not expose router shadow output to the browser.
It does not persist router shadow evidence.
It does not enable router model selection.
It does not mutate CT101.
It does not call live model endpoints.

## Current Verified Starting Point

Phase 14I-AO confirmed that the future evidence target should remain controller-owned and should follow the existing laptop/controller database schema surface pattern.

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

This phase drafts the future schema-only migration plan without creating the schema artifact.

The goal is to define what a later gated schema-only phase should create, how it should be named, what data it may store, and what it must not store.

## Candidate Future Migration File

A later gated schema-only phase may consider adding a migration artifact in the existing controller-owned schema family.

Candidate future file name:

`ops/db/laptop-app-schema-v3-router-shadow-evidence.sql`

This phase does not create that file.

A later phase should only create it after confirming:

- repo baseline is clean,
- backup procedure is ready,
- rollback procedure is ready,
- schema target is still controller-owned,
- no writer code is included,
- no runtime route changes are included,
- no browser output changes are included.

## Candidate Future Migration Version Marker

A later schema-only phase may use this migration marker:

`stage-14i-router-shadow-evidence`

The marker should be recorded through the existing `app_schema_migrations` pattern.

This phase does not insert the marker.

## Candidate Future Table Name

A later schema-only phase may create this table:

`queued_chat_router_shadow_evidence`

This phase does not create the table.

## Candidate Future Table Purpose

The table should record bounded, privacy-preserving metadata that lets us compare queued-chat router shadow decisions over time.

It should support later analysis of:

- whether the shadow router would have selected a different route,
- whether the decision was confident,
- which policy version produced the shadow decision,
- whether the user-visible model choice remained unchanged,
- whether the shadow decision would have stayed within safe route boundaries.

It must not become a raw prompt archive.

It must not become a queue payload archive.

It must not become browser-visible debug output.

## Candidate Future Column Groups

A later schema-only phase may consider these column groups.

### Identity and relationship metadata

- evidence id,
- created timestamp,
- related job id if available,
- authenticated user id if safely available,
- request surface name,
- route name.

The relationship must not mutate any job row.

Job 23 must never be archived, deleted, rewritten, or mutated.

### Shadow decision metadata

- shadow enabled flag observed by helper,
- router policy version,
- router decision status,
- candidate route key,
- candidate model tier,
- candidate model family,
- decision confidence,
- escalation reason code,
- fallback reason code.

### Live behavior comparison metadata

- live requested model name if already present as bounded metadata,
- live path preserved flag,
- browser exposed flag,
- evidence persisted by writer flag,
- route behavior changed flag.

For the current and near-future phases, these should remain false or unchanged as appropriate.

### Safety and privacy metadata

- safe allowlist version,
- rejected unsafe field count,
- redaction count,
- blocked field family code,
- writer gate name,
- writer gate enabled flag.

The future writer must still be default-off until separately approved.

## Blocked Fields

A future schema or writer must not store:

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
- full payload blobs,
- full router traces,
- full model responses,
- raw model prompt templates,
- raw system prompts.

## Candidate Future Index Strategy

A later schema-only phase may consider narrow indexes for:

- created timestamp,
- related job id,
- request surface,
- router policy version,
- decision status.

Indexes should support safe operational lookup only.

Indexes must not encourage raw prompt, raw payload, or secret-bearing searches.

## Future Migration Apply Boundary

A later schema-only phase may create and apply the schema only if explicitly gated.

That later phase must still avoid:

- writer code,
- persistence calls from `/api/chat/queued`,
- model calls,
- scheduler changes,
- requested model selection changes,
- browser-visible output,
- backend direct `/jobs` gating,
- Study UI `requested_model` removal,
- legacy fallback removal,
- CT101 mutation,
- job 23 mutation.

## Future Writer Boundary

A writer helper must be a separate later phase after schema creation is proven.

The future writer must:

- be default-off,
- use a strict field allowlist,
- reject unsafe fields,
- avoid raw payload storage,
- avoid raw message storage,
- fail closed without blocking queued-chat job creation,
- never change live model selection,
- never return evidence to the browser.

## Backup and Rollback Requirement

Before any future schema migration is applied, the phase must verify the existing backup and restore path.

The future migration phase must document:

- backup command,
- rollback command or rollback procedure,
- restore drill expectation,
- verification command,
- failure isolation rule,
- confirmation that no job records were mutated.

## Phase 14I-AP Validation Scope

This phase validates only that:

- this schema-only migration draft plan exists,
- the scope remains docs/smoke only,
- runtime code still compiles,
- no SQL artifact is added,
- no migration file is added,
- no executable schema code is added,
- no writer marker is added outside docs/smoke,
- no router model selection is enabled,
- no browser exposure marker is introduced,
- no CT101 mutation path is introduced.

## Exit Criteria

Phase 14I-AP is complete when:

- this document exists,
- its static smoke exists,
- the smoke passes,
- `edge_controller.py` still compiles,
- git diff contains only this docs/smoke phase,
- the phase is committed, tagged, and pushed.

After Phase 14I-AP, the next safe follow-up can be a schema-only SQL artifact plan or preflight, still without applying the migration and still without adding a writer.
