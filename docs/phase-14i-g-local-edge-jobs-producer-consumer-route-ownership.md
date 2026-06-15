# Phase 14I-G - Local Edge Jobs Producer/Consumer Route Ownership

Status: inspection recorded

## Purpose

Phase 14I-G records which routes still create or consume local Edge `jobs` rows versus which paths use CT101/Postgres `app_jobs`.

This phase does not mutate jobs, delete jobs, activate workers, or change routing.

## Scope

Allowed:

- Documentation
- Read-only smoke script
- Read-only local code inspection
- Read-only GET requests
- Redacted local queue summary inspection
- Compile validation

Blocked:

- Job deletion
- Job archival
- Job forwarding
- CT101 modification
- Persistent lane worker activation
- Router rollout
- Warmup execution
- Model generate/chat calls
- Model unloading
- Authentication weakening
- Runtime service mutation
- Power automation changes
- Service starts/stops/restarts
- Mutating HTTP calls
- Raw prompt/context dumping

## Starting Checkpoint

- HEAD: 525f99b
- Tag: controller-phase-14i-f-edge-scheduler-vs-ct101-surface-map-2026-06-15
- Phase 14I-A smoke: passed
- Phase 14I-B smoke: passed
- Phase 14I-C smoke: passed
- Phase 14I-D smoke: passed
- Phase 14I-E smoke: passed
- Phase 14I-F smoke: passed
- Repo status: clean
- Compile: passed

## Main Finding

The queued job that keeps appearing in `/scheduler/preview` is a local Edge `jobs` row.

Observed local Edge queue state:

- Local Edge jobs total: 22
- Local Edge jobs queued: 1
- Local Edge jobs forwarded: 20
- Local Edge jobs failed: 1
- Queued job observed: job_id 23
- Job type: ollama_chat
- Requested model: gemma4:e4b
- Attempts: 3
- Forwarded at: null
- Selected worker: null
- Candidate workers: none
- Edge worker registry total: 0
- Edge worker registry available: 0

## Local Edge Jobs Producers

The inspection found active local SQLite `jobs` producers and surfaces:

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
- `POST /api/chat/queued`
- `GET /api/chat/queued/{job_id}`

The helper `_public_create_ollama_job(...)` inserts into the local SQLite `jobs` table.

This means some public/controller routes still use the older local Edge queue path.

## Local Edge Jobs Consumers

The local Edge scheduler preview uses:

- local `jobs` table
- local `workers` table

Specifically, `/scheduler/preview` selects queued rows from local `jobs` and then scores local Edge `workers`.

Because the local Edge worker registry is empty, job 23 has no selectable worker.

## Legacy Tick Finding

The legacy `/tick` endpoint is currently a compatibility shim.

It does not execute the old scheduler path when `EDGE_LEGACY_TICK_COMPAT_SHIM` remains enabled.

Therefore, the queued local Edge job remains queued unless a separate, explicit safe action handles it later.

## CT101 App Jobs Path

The CT101 app queue uses Postgres `app_jobs`, not local Edge `jobs`.

Observed CT101 app queue state from `/system/status`:

- CT101 worker state: online
- CT101 app queue queued: 0
- CT101 app queue running: 0
- CT101 app queue complete: 41
- CT101 app queue failed: 1
- Persistent cutover ready: false
- Persistent cutover reasons:
  - primary_worker_unfiltered
  - persistent_lane_workers_not_active

Known CT101 app job producers include:

- `edge_modules/chat_queue_creation.py`
- `edge_modules/chat_queue_persistence.py`
- `edge_modules/chat_queue_real_user_creation.py`
- `edge_modules/laptop_queue.py`

The real-user CT101 app job creation path includes lane metadata such as:

- routing_contract_version
- model_lane
- queue_lane

## Important Boundary

Local Edge `jobs` and CT101 `app_jobs` are separate queues.

Job 23 being queued in local Edge `jobs` does not mean CT101 has queued app work.

CT101 being online does not make local Edge `/scheduler/preview` select a worker.

## Privacy Finding

Diagnostics must not print raw local Edge prompts or CT101 prompt/context bodies.

Future smokes must use redacted summaries only.

Allowed safe queue fields include:

- id
- job_type
- requested_model
- status
- attempts
- last_error_present
- created_at
- updated_at
- forwarded_at
- user_id
- prompt_length

## Current Decision

Do not enable workers yet.

Do not delete or mutate job 23 yet.

Do not change CT101.

Do not enable router rollout.

Do not start warmup execution.

The next safe work should be a docs-only or read-only retirement plan for the old local Edge queued-job path, including:

1. Which public routes should stop creating local Edge `jobs`.
2. Which routes should be redirected to CT101 `app_jobs` or deprecated.
3. How to safely handle existing local Edge queued job 23.
4. How to preserve privacy-safe diagnostics.

## Definition of Done

Phase 14I-G is complete when:

- This report exists.
- The read-only smoke script exists.
- The smoke script is executable.
- The smoke script verifies local Edge job 23 remains queued without printing its prompt.
- The smoke script verifies `/scheduler/preview` remains blocked with no selected worker.
- The smoke script verifies CT101 app queue has no queued/running work through `/system/status`.
- The smoke script verifies `_public_create_ollama_job` inserts into local `jobs`.
- The smoke script verifies CT101 app job modules insert into `app_jobs`.
- The smoke script does not call mutating HTTP methods.
- The smoke script does not start/stop/restart/enable/disable services.
- The smoke script does not call model generate/chat endpoints.
- Compile passes.
- Smoke passes.
- Commit, tag, and push complete.
