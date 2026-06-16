# Phase 14I-AS Router Shadow Evidence SQL Artifact Apply-Readiness Gate

Phase 14I-AS records the apply-readiness gate for the router shadow evidence SQL artifact.

This phase is documentation and static smoke validation only.

It does not apply a database migration.
It does not call `psql`.
It does not source database environment files.
It does not touch the database.
It does not add a writer.
It does not change runtime behavior.
It does not expose router shadow output to the browser.
It does not persist router shadow evidence at runtime.
It does not enable router model selection.
It does not mutate CT101.
It does not call live model endpoints.

## Current Verified Starting Point

Phase 14I-AR added the schema-only SQL artifact:

`ops/db/laptop-app-schema-v3-router-shadow-evidence.sql`

The current runtime contract remains unchanged:

- `/api/chat/queued` calls `_phase14iag_queued_chat_router_shadow_decision(guard_payload)`.
- `EDGE_QUEUED_CHAT_ROUTER_SHADOW_ENABLED` remains default-off.
- The shadow helper return value is discarded.
- Live `requested_model` pass-through remains unchanged.
- No router shadow output is returned to the browser.
- No router shadow evidence is persisted by runtime code.
- No writer exists for router shadow evidence.
- The SQL artifact exists but has not been applied by this phase.

## Apply-Readiness Purpose

This phase defines the gate that must pass before any later phase applies the SQL artifact.

The apply step must remain separate from writer creation and router activation.

## Required Apply Gate

A later apply phase must verify all of the following before touching the database:

1. Repo baseline is clean.
2. Latest HEAD and tag are known.
3. SQL artifact file exists.
4. SQL artifact hash or diff is reviewed.
5. Backup script exists.
6. Restore script exists.
7. Restore drill script exists.
8. Database target is confirmed as the controller-owned database.
9. CT101 is not the target.
10. No runtime writer is included.
11. No route behavior change is included.
12. No browser output change is included.
13. No router model selection change is included.
14. No backend direct `/jobs` gating is included.
15. No Study UI `requested_model` removal is included.
16. No legacy fallback removal is included.
17. Job 23 will not be archived, deleted, rewritten, or mutated.

## Backup Requirement for Future Apply Phase

A future apply phase must run or verify a fresh backup before applying the SQL artifact.

The output must confirm backup success without exposing secrets.

## Restore and Rollback Requirement for Future Apply Phase

A future apply phase must document the rollback path before applying.

Because this artifact creates a new table and migration marker, rollback planning must explain how to recover if:

- SQL apply fails mid-transaction,
- migration marker already exists,
- table already exists,
- index creation conflicts,
- backup fails,
- restore drill fails,
- database target is wrong.

## Future Apply Validation

A future apply phase must verify, without dumping sensitive data:

- table existence,
- migration marker existence,
- expected indexes,
- expected constraints,
- no rows are required,
- no app job rows are mutated,
- no browser response includes evidence,
- runtime behavior still compiles.

## Writer Separation Rule

Applying the SQL artifact must not add a writer.

A writer helper must remain a later default-off phase.

The future writer must:

- use a strict allowlist,
- reject unsafe fields,
- avoid raw prompt storage,
- avoid raw message storage,
- avoid raw request body storage,
- avoid raw queue summary storage,
- fail without blocking queued-chat job creation,
- never change live model selection,
- never return evidence to the browser.

## Apply Stop Conditions

A future apply phase must stop before touching the database if:

- repo is dirty,
- SQL artifact differs from reviewed artifact,
- backup path is unavailable,
- restore path is unavailable,
- database target is uncertain,
- CT101 mutation would be required,
- live model endpoint calls would be required,
- writer code is bundled into the apply,
- router activation is bundled into the apply,
- job 23 would be touched,
- secrets would be printed.

## Prior Smoke Note

Older pre-artifact smokes that required the v3 SQL file to be absent are superseded after Phase 14I-AR.

The current validation authority for the artifact existing is the Phase 14I-AR smoke and later phases.

## Phase 14I-AS Validation Scope

This phase validates only that:

- this apply-readiness document exists,
- its smoke exists,
- the SQL artifact exists,
- runtime code still compiles,
- backup/restore surface files exist,
- changed files are limited to this docs/smoke phase,
- no database apply command is executed,
- no writer marker is introduced outside docs/smoke or the existing SQL artifact,
- no route behavior is changed,
- no browser exposure is introduced,
- no CT101 mutation path is introduced.

## Exit Criteria

Phase 14I-AS is complete when:

- this document exists,
- its static smoke exists,
- the smoke passes,
- `edge_controller.py` still compiles,
- git diff contains only this docs/smoke phase,
- the phase is committed, tagged, and pushed.

After Phase 14I-AS, the next safe follow-up can be an explicitly gated SQL apply preflight or backup verification phase. It still must not add a writer.
