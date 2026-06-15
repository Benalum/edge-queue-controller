# Phase 14I-I - Read-Only Active `/api/chat/queued` Route Proof

Status: inspection recorded

## Purpose

Phase 14I-I records read-only proof that `/api/chat/queued` is not part of the old local Edge `jobs` retirement set.

This phase proves route ownership by source inspection and read-only runtime diagnostics only.

## Scope

Allowed:

- Documentation
- Read-only smoke script
- Static source inspection
- Secret-safe runtime flag inspection
- Read-only GET requests
- Redacted queue diagnostics
- Compile validation

Blocked:

- POST to `/api/chat/queued`
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

- HEAD: 6e3e393
- Tag: controller-phase-14i-h-local-edge-jobs-retirement-plan-2026-06-15
- Phase 14I-G smoke: passed
- Phase 14I-H smoke: passed
- Repo status before inspection: clean
- Compile: passed

## Main Finding

`/api/chat/queued` should not be retired with the old local Edge `jobs` routes.

The create route exists at:

- `POST /api/chat/queued`

The status route exists at:

- `GET /api/chat/queued/{job_id}`

Static route classification found:

- route exists: true
- route calls real-user app-job helper: true
- route calls legacy `_public_create_ollama_job`: false
- route directly inserts into local `jobs`: false
- route checks synthetic-only gate: true
- route checks real-user gate: true
- route checks feature-enabled gate: true

## Canonical Path Classification

When the correct feature gates allow real-user queued chat, `/api/chat/queued` calls:

- `_s5f19_create_real_user_queued_chat_job(...)`

That helper comes from:

- `edge_modules/chat_queue_real_user_creation.py`

The real-user helper creates CT101/Postgres `app_jobs` rows and includes lane metadata:

- `routing_contract_version`
- `model_lane`
- `queue_lane`

Synthetic queued chat also uses an app-jobs style queued-chat helper path, not `_public_create_ollama_job`.

## Legacy Path Exclusion

`/api/chat/queued` does not directly call:

- `_public_create_ollama_job(...)`

`/api/chat/queued` does not directly contain:

- `INSERT INTO jobs`

Therefore it is not one of the old local Edge `jobs` producers identified for retirement.

## Runtime Caveat

This phase intentionally did not POST to `/api/chat/queued`.

Because no job was created, this phase proves source route ownership and read-only runtime safety, not live create success.

A future controlled phase may test live creation only after explicit gates and only if it is safe to create an app_jobs row.

## Routes Still Considered Local Edge Retirement Candidates

The following remain retirement or compatibility-label candidates:

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

## Queue State During Inspection

Local Edge queue remained unchanged:

- total: 22
- queued: 1
- forwarded: 20
- failed: 1
- stale queued job: 23
- prompt output: redacted only

CT101 app queue remained separate:

- queued: 0
- running: 0
- complete: 41
- failed: 1

## Current Decision

Preserve `/api/chat/queued`.

Do not retire `/api/chat/queued` as part of local Edge jobs cleanup.

Do not delete or mutate job 23 yet.

Do not forward job 23 to CT101.

Do not activate workers.

Do not mutate CT101.

## Recommended Next Step

Phase 14I-J should add a disabled-by-default legacy local Edge jobs retirement flag plan.

The target should be old local Edge routes and helpers, not `/api/chat/queued`.

## Definition of Done

Phase 14I-I is complete when:

- This proof document exists.
- The read-only smoke script exists.
- The smoke script is executable.
- The smoke verifies `/api/chat/queued` exists.
- The smoke verifies `/api/chat/queued` does not call `_public_create_ollama_job`.
- The smoke verifies `/api/chat/queued` does not directly insert into local `jobs`.
- The smoke verifies the real-user app_jobs helper import/call exists.
- The smoke verifies app_jobs modules still insert into `app_jobs`.
- The smoke verifies local Edge job 23 is only summarized with prompt redaction.
- The smoke verifies CT101 app queue remains separate.
- The smoke blocks mutation, model execution, and raw queue dumps.
- Compile passes.
- Smoke passes.
- Commit, tag, and push complete.
