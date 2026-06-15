# Phase 14I-T - Study UI Queued-Chat Adapter Plan

Status: read-only adapter plan recorded

## Purpose

Phase 14I-T records the safe frontend adapter plan for migrating the Study UI companion flow from direct local Edge `jobs` routes to the app_jobs-backed queued chat route.

This phase does not change runtime behavior.

## Starting Checkpoint

- HEAD: 8165854
- Tag: controller-phase-14i-s-study-ui-companion-queue-migration-inspection-2026-06-15

## Current Study UI Behavior

The current live Study UI file is:

- `frontend/study-ui/app.js`

Current direct local jobs usage:

- `sendCompanionToApi(...)` posts to `` `${base}/jobs` ``
- `pollJob(...)` polls fallback path `` `${base}/jobs/${jobId}` ``
- `pollJob(...)` also contains legacy fallback path `` `${base}/job/${jobId}` ``

Current Study UI submit body for direct `/jobs`:

- `job_type: "ollama_chat"`
- `prompt`
- `requested_model: "gemma4:e4b"`

Current Study UI does not reference:

- `/api/chat/queued`

## Exact Queued-Chat Request Model

The exact backend request model is `_S5F9QueuedChatRequest`.

Accepted fields:

- `message`
- `chat_id`
- `requested_model`
- `mode`
- `user_id`
- `authenticated_user_id`

Important rejected/not-present frontend adapter fields:

- `prompt`
- `model`

The queued-chat route uses:

- `request.model_dump(exclude_none=True)`
- `requested_model=guard_payload.get("requested_model") or guard_payload.get("model")`

However, because `model` is not an accepted request-model field, the frontend adapter should use `requested_model`.

Because `prompt` is not an accepted request-model field, the frontend adapter should put the fully built Study companion prompt into `message`.

## Queued-Chat Backend Routes

The app_jobs-backed queued chat routes exist:

- `POST /api/chat/queued`
- `GET /api/chat/queued/{job_id}`

The create route returns:

- `job_id`
- `status`
- `chat_id`
- `user_message_id`
- `payload_json`

The status route reads from:

- `app_jobs`

## Safe Adapter Plan

A later implementation phase may migrate the Study UI companion flow as follows:

1. Add `/api/chat/queued` as the preferred submit target before direct `/jobs`.
2. Submit body:
   - `message: prompt`
   - `requested_model: "gemma4:e4b"`
   - optional `mode` only if already supported by the current queued-chat guard path
3. Do not submit `prompt`.
4. Do not submit `model`.
5. Update `pollJob(...)` fallback order:
   - returned `poll_url` first
   - `/api/chat/queued/{jobId}` second
   - `/jobs/{jobId}` third
   - `/job/{jobId}` last
6. Keep direct `/jobs` submit fallback for one migration phase.
7. Keep direct `/jobs` poll fallback for one migration phase.
8. Do not gate direct `POST /jobs` or `GET /jobs` until the Study UI no longer references direct `/jobs`.

## Safety Notes

Phase 14I-T is read-only/static.

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

## Next Safe Step

Phase 14I-U may implement a default-preserving Study UI adapter.

Candidate Phase 14I-U implementation:

- Add `/api/chat/queued` as the first Study UI companion attempt.
- Send `{ message: prompt, requested_model: "gemma4:e4b" }`.
- Add `/api/chat/queued/{jobId}` as a polling fallback before direct `/jobs/{jobId}`.
- Keep direct `/jobs` submit and poll fallbacks.
- Add smoke coverage proving:
  - `/api/chat/queued` is now referenced once or more in Study UI.
  - direct `/jobs` fallback still exists.
  - direct `/jobs` is not gated yet.
  - frontend syntax passes.
  - no live model or queue calls are made by smoke tests.
