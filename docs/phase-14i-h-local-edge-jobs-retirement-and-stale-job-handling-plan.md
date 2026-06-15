# Phase 14I-H - Local Edge Jobs Retirement and Stale Job Handling Plan

Status: design recorded

## Purpose

Phase 14I-H records a safe retirement plan for the old local Edge `jobs` queue path and the currently observed stale local Edge queued job 23.

This phase is documentation and read-only validation only.

## Scope

Allowed:

- Documentation
- Read-only smoke script
- Read-only source inspection
- Read-only GET requests
- Redacted queue diagnostics
- Compile validation

Blocked:

- Job deletion
- Job archival
- Job forwarding
- Worker activation
- CT101 modification
- Router rollout
- Warmup execution
- Model generate/chat calls
- Runtime service mutation
- Power automation mutation
- Raw prompt/context dumping

## Starting Checkpoint

- HEAD: a2f0281
- Tag: controller-phase-14i-g-local-edge-jobs-route-ownership-2026-06-15
- Phase 14I-F smoke: passed
- Phase 14I-G smoke: passed
- Repo status before inspection: clean
- Compile: passed

## Current Runtime Finding

The local Edge queue still contains one queued job:

- job_id: 23
- queue: local Edge SQLite `jobs`
- status: queued
- requested_model: gemma4:e4b
- attempts: 3
- forwarded_at: null
- prompt output: redacted only

The CT101 app queue remains separate:

- CT101 app queue queued: 0
- CT101 app queue running: 0
- CT101 app queue complete: 41
- CT101 app queue failed: 1
- Persistent lane cutover ready: false
- Persistent lane blockers:
  - primary_worker_unfiltered
  - persistent_lane_workers_not_active

## Local Edge Routes That Must Be Retired, Redirected, or Preserved Carefully

The following routes still touch or expose the old local Edge `jobs` surface:

- `POST /jobs`
- `GET /jobs`
- `GET /queue/summary`
- `POST /public/jobs`
- `GET /public/jobs/{job_id}`
- `GET /public/jobs`
- `POST /public/companion/chat`
- `POST /api/companion/chat`
- `GET /api/chat/queue/status`
- `GET /public/chat/queue/status`

These are the primary retirement/deprecation candidates because they create, list, or report local SQLite `jobs`.

## Canonical Route That Needs Extra Care

`POST /api/chat/queued` should not be blindly removed.

Historical docs and current app-job modules indicate this route is the newer real-user queued-chat path intended to create CT101/Postgres `app_jobs` when the correct feature flags and ownership path are active.

Therefore:

1. Prove its currently active create path before modifying it.
2. Preserve the real-user `app_jobs` creation path.
3. Remove only old local Edge `jobs` dependencies.
4. Keep ownership, authentication, and polling behavior intact.
5. Do not collapse `/api/chat/queued` into `/public/jobs`.

## Helper Retirement Target

`_public_create_ollama_job(...)` is the old local Edge job producer.

It inserts into local SQLite `jobs`, not CT101/Postgres `app_jobs`.

Retirement plan:

1. Stop live public companion routes from calling `_public_create_ollama_job`.
2. Preserve it temporarily only for legacy read-only compatibility if needed.
3. Add explicit legacy naming or comments before deletion.
4. Remove it only after frontend and route ownership checks show no live dependency.

## Queue Status Retirement Target

`GET /api/chat/queue/status` and `GET /public/chat/queue/status` currently read the local Edge `jobs` table.

Retirement plan:

1. Do not use local Edge `jobs` as the source of truth for active Companion or Chat status.
2. Replace status reads with CT101/app queue status or real-user `app_jobs` status.
3. Keep any old endpoint temporarily as a compatibility endpoint only if it clearly labels local Edge `jobs` as legacy.
4. Never show raw prompt/context in status responses.

## Stale Job 23 Handling Plan

Do not delete or mutate job 23 yet.

Safe future handling should happen in a dedicated controlled phase after this plan is committed.

Recommended future options, from safest to most invasive:

1. Keep job 23 as a known legacy diagnostic marker until all local Edge job routes are retired.
2. Add a dry-run-only stale legacy job report that identifies job 23 by metadata without prompt output.
3. Add a guarded admin-only archive action that requires an explicit confirmation phrase.
4. Archive job 23 by changing status to a clear terminal legacy status such as `retired_legacy`.
5. Never forward job 23 to CT101 automatically because its payload belongs to the old local Edge queue path.

## Required Gates Before Any Runtime Change

Before changing route behavior:

- Repo must be clean.
- Compile must pass.
- Phase 14I-F smoke must pass.
- Phase 14I-G smoke must pass.
- This Phase 14I-H smoke must pass.
- CT101 app queue must show queued=0 and running=0.
- Local Edge job 23 must be summarized with prompt redaction only.
- No worker registry activation may happen.
- No model call may happen.
- No CT101 mutation may happen.

## Recommended Next Implementation Sequence

1. Phase 14I-I: read-only active route proof for `/api/chat/queued`.
2. Phase 14I-J: add disabled-by-default legacy local Edge jobs retirement flags.
3. Phase 14I-K: move or label `/api/chat/queue/status` away from local Edge `jobs`.
4. Phase 14I-L: redirect/deprecate `/public/companion/chat` and `/api/companion/chat` local Edge producer behavior.
5. Phase 14I-M: add admin-only dry-run stale legacy job report.
6. Phase 14I-N: controlled archive of job 23 only if still safe and explicitly confirmed.

## Definition of Done

Phase 14I-H is complete when:

- This plan exists.
- The read-only smoke script exists.
- The smoke script is executable.
- The smoke script verifies the local Edge retirement candidates.
- The smoke script verifies `_public_create_ollama_job` still writes local `jobs`.
- The smoke script verifies CT101 app job modules still write `app_jobs`.
- The smoke script verifies local Edge job 23 is still summarized without raw prompt output.
- The smoke script verifies CT101 app queue remains separate.
- The smoke script blocks mutation, model execution, and raw queue dumps.
- Compile passes.
- Smoke passes.
- Commit, tag, and push complete.
