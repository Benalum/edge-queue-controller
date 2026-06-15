# Phase 14I-S - Study UI Companion Queue Migration Inspection

Status: read-only inspection recorded

## Purpose

Phase 14I-S records the read-only inspection of the Study UI companion queue path.

This phase does not change runtime behavior.

## Starting Checkpoint

- HEAD: 594cab7
- Tag: controller-phase-14i-r-direct-local-jobs-usage-inspection-2026-06-15

## Study UI Current State

The current live Study UI file is:

- `frontend/study-ui/app.js`

The Study UI companion flow currently uses direct local Edge `jobs` routes:

- `sendCompanionToApi(...)` posts queued companion work to `` `${base}/jobs` ``
- `pollJob(...)` polls fallback path `` `${base}/jobs/${jobId}` ``
- `pollJob(...)` also contains legacy fallback `` `${base}/job/${jobId}` ``

The Study UI does not currently reference:

- `/api/chat/queued`

## Study UI Request Shape

The current direct `/jobs` submit body is:

- `job_type: "ollama_chat"`
- `prompt`
- `requested_model: "gemma4:e4b"`

The prompt is built by `buildCompanionPrompt(...)` and includes Study card context when available.

## Backend Queued Chat State

The controller has app_jobs-backed queued chat routes:

- `POST /api/chat/queued`
- `GET /api/chat/queued/{job_id}`

The create route returns queued job fields including:

- `job_id`
- `status`
- `chat_id`
- `user_message_id`
- `payload_json`

The status route reads from `app_jobs`.

## Compatibility Finding

The migration should not be a blind route swap yet.

Reasons:

- Study UI currently expects direct `/jobs` submit behavior.
- Study UI currently polls direct `/jobs/{jobId}` fallback paths.
- Study UI has no `/api/chat/queued` status polling path.
- The backend queued chat route exists and is app_jobs-backed, but the frontend poll adapter needs to route app_jobs job IDs to `/api/chat/queued/{job_id}`.

## Safety Notes

Phase 14I-S is read-only/static.

No frontend behavior is changed.

No backend behavior is changed.

No jobs are created.

No jobs are deleted.

No jobs are archived.

No jobs are forwarded.

Job 23 is not mutated.

CT101 is not modified.

No model calls are made.

No runtime service mutation is performed.

No raw queue summary or prompt/context dump is performed.

## Decision Note

Before direct `/jobs` can be gated, the Study UI companion queue path must be migrated or adapted.

Recommended next step:

- Add a default-preserving frontend adapter plan first.
- Then implement a small guarded migration in a later phase.
- Only after Study UI no longer uses direct `/jobs`, consider gating direct `POST /jobs` and `GET /jobs`.

## Candidate Phase 14I-T Scope

Phase 14I-T should document the frontend migration plan.

Candidate plan:

1. Add `/api/chat/queued` as the preferred Study UI companion submit target.
2. Send both `message` and `prompt` if required by the backend request model.
3. Preserve `requested_model: "gemma4:e4b"`.
4. Update `pollJob(...)` so app_jobs queued chat jobs poll `/api/chat/queued/{job_id}`.
5. Keep direct `/jobs` as fallback during one migration phase.
6. Do not gate direct `/jobs` until the Study UI migration is validated.
