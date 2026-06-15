# Phase 14I-K - Disabled Legacy Local Edge Jobs Flag Helpers

Status: helper implementation added

## Purpose

Phase 14I-K adds disabled legacy local Edge `jobs` retirement flag helpers without wiring those helpers into route behavior yet.

This is the first implementation step after the Phase 14I-J flag plan.

## Scope

Allowed:

- Add helper functions
- Add documentation
- Add read-only/static smoke coverage
- Evolve the Phase 14I-J smoke so it remains valid after this implementation step
- Compile validation

Blocked:

- Route behavior changes
- Job creation
- Job deletion
- Job archival
- Job forwarding
- Worker activation
- CT101 mutation
- Router rollout
- Warmup execution
- Model generate/chat calls
- Runtime service mutation
- Power automation mutation
- Raw prompt/context dumping

## Starting Checkpoint

- HEAD: 4a26684
- Tag: controller-phase-14i-j-disabled-legacy-local-edge-jobs-retirement-flag-plan-2026-06-15

## Helper Functions Added

The following helpers were added to `edge_controller.py`:

- `_phase14ik_legacy_local_jobs_routes_enabled()`
- `_phase14ik_legacy_companion_local_job_create_enabled()`
- `_phase14ik_legacy_local_queue_status_enabled()`
- `_phase14ik_legacy_local_jobs_admin_archive_enabled()`

They are backed by:

- `EDGE_LEGACY_LOCAL_JOBS_ROUTES_ENABLED`
- `EDGE_LEGACY_COMPANION_LOCAL_JOB_CREATE_ENABLED`
- `EDGE_LEGACY_LOCAL_QUEUE_STATUS_ENABLED`
- `EDGE_LEGACY_LOCAL_JOBS_ADMIN_ARCHIVE_ENABLED`

## Defaults

The safe compatibility defaults are:

- `EDGE_LEGACY_LOCAL_JOBS_ROUTES_ENABLED`: default enabled
- `EDGE_LEGACY_COMPANION_LOCAL_JOB_CREATE_ENABLED`: default enabled
- `EDGE_LEGACY_LOCAL_QUEUE_STATUS_ENABLED`: default enabled
- `EDGE_LEGACY_LOCAL_JOBS_ADMIN_ARCHIVE_ENABLED`: default disabled

This means the first three helpers preserve current behavior by default, and the future admin archive path remains disabled by default.

## No Behavior Change

The helpers are intentionally not wired into route handlers in Phase 14I-K.

Therefore:

- `/api/chat/queued` remains preserved.
- Legacy local Edge job routes are not disabled yet.
- Companion legacy local job creation is not disabled yet.
- Local queue status behavior is not changed yet.
- Job 23 is not mutated.
- No CT101 behavior changes.
- No worker behavior changes.

## Why Phase 14I-J Smoke Was Evolved

Phase 14I-J originally required that no runtime flag helpers exist because it was a docs-only flag plan.

Phase 14I-K is the next expected implementation phase, so the Phase 14I-J smoke was evolved to accept the complete Phase 14I-K helper block while still rejecting partial implementations.

## Next Safe Step

Phase 14I-L should add disabled-mode static/isolated helper tests or begin gating one legacy route family behind the helpers while proving default behavior unchanged.

Do not archive job 23 yet.

Do not wire admin archive behavior yet.

Do not change `/api/chat/queued`.

## Definition of Done

Phase 14I-K is complete when:

- The helper block exists.
- Helper defaults are verified.
- Helper env override behavior is verified in isolated execution.
- Helper functions are not called by routes yet.
- `/api/chat/queued` preservation remains documented.
- Phase 14I-J smoke still passes after helper implementation.
- Phase 14I-K smoke passes.
- Compile passes.
- Commit, tag, and push complete.
