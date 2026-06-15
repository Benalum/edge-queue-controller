# Phase 14I-J - Disabled-by-Default Legacy Local Edge Jobs Retirement Flag Plan

Status: design recorded

## Purpose

Phase 14I-J defines the disabled-by-default flag plan for retiring old local Edge `jobs` routes safely.

This phase does not change route behavior.

## Scope

Allowed:

- Documentation
- Read-only smoke script
- Static source inspection
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

- HEAD: 6d84deb
- Tag: controller-phase-14i-i-api-chat-queued-route-proof-2026-06-15

## Core Decision

Do not retire `/api/chat/queued`.

`/api/chat/queued` is the app_jobs-oriented queued chat route and must be preserved.

Legacy local Edge `jobs` retirement should target only the old local Edge job producer/status surfaces.

## Proposed Future Flags

All flags must default to safe compatibility behavior.

### EDGE_LEGACY_LOCAL_JOBS_ROUTES_ENABLED

Default: `1`

Purpose:

- Keeps old local Edge job routes available while transition work is incomplete.
- Allows future controlled disablement.

When set to `0` in a future implementation:

- `POST /public/jobs` should reject creation with a clear retired/disabled response.
- `GET /public/jobs/{job_id}` may remain read-only for legacy status if privacy-safe.
- `GET /public/jobs` should be admin-only or disabled.
- Raw prompt output must remain blocked.

### EDGE_LEGACY_COMPANION_LOCAL_JOB_CREATE_ENABLED

Default: `1`

Purpose:

- Separately gates legacy Companion routes that still call `_public_create_ollama_job(...)`.

When set to `0` in a future implementation:

- `POST /public/companion/chat`
- `POST /api/companion/chat`

must stop creating local Edge `jobs`.

They should either:

1. Return a clear disabled/deprecated response, or
2. Redirect to the preserved `/api/chat/queued` app_jobs route only after a separate proven implementation phase.

### EDGE_LEGACY_LOCAL_QUEUE_STATUS_ENABLED

Default: `1`

Purpose:

- Separately gates local Edge `jobs` status summaries used by older UI pieces.

When set to `0` in a future implementation:

- `GET /api/chat/queue/status`
- `GET /public/chat/queue/status`

must stop reporting local Edge `jobs` as the active Companion/Chat queue.

They may return a compatibility response saying the legacy queue is retired, while pointing clients to `/api/chat/queued/{job_id}` for app_jobs-backed status.

### EDGE_LEGACY_LOCAL_JOBS_ADMIN_ARCHIVE_ENABLED

Default: `0`

Purpose:

- Provides a future admin-only path for controlled stale legacy job archival.

This flag must remain disabled by default.

A future archive action must require:

- admin authentication
- explicit confirmation phrase
- dry-run preview
- prompt redaction
- audit/event entry
- no forwarding to CT101

## Stale Job 23 Policy

Do not delete or mutate job 23 yet.

Do not forward job 23 to CT101.

Job 23 belongs to the local Edge `jobs` queue and is useful as a known legacy diagnostic marker until the retirement gates are implemented and proven.

## Required Future Implementation Order

1. Add disabled-by-default flag helpers only.
2. Add read-only smokes proving default behavior unchanged.
3. Add disabled-mode smokes using env override or isolated helper tests.
4. Gate legacy route creation.
5. Gate legacy queue status display.
6. Add admin-only dry-run stale job archive report.
7. Only later consider a controlled archive action for job 23.

## Definition of Done

Phase 14I-J is complete when:

- This plan exists.
- The smoke script exists.
- The smoke script is executable.
- The smoke verifies `/api/chat/queued` preservation is documented.
- The smoke verifies the proposed flags are documented with safe defaults.
- The smoke verifies local Edge retirement candidates still exist.
- The smoke verifies no route behavior changed.
- The smoke blocks mutation, model execution, and raw queue dumps.
- Compile passes.
- Smoke passes.
- Commit, tag, and push complete.
