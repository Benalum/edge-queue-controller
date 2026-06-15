# Phase 14I-U - Study UI Queued-Chat Adapter

Status: implemented with legacy fallback preserved

## Purpose

Phase 14I-U implements the default-preserving Study UI queued-chat adapter planned in Phase 14I-T.

The Study UI companion flow now prefers the app_jobs-backed queued chat route before falling back to legacy local Edge `jobs`.

## Starting Checkpoint

- HEAD: c5fc28f
- Tag: controller-phase-14i-t-study-ui-queued-chat-adapter-plan-2026-06-15

## Files Changed

- `frontend/study-ui/app.js`
- `docs/phase-14i-u-study-ui-queued-chat-adapter.md`
- `ops/smoke/check-phase-14i-u-study-ui-queued-chat-adapter.sh`

## Implementation

`sendCompanionToApi(...)` now tries the app_jobs-backed queued chat route first:

- submit path: `` `${base}/chat/queued` ``
- request body:
  - `message: prompt`
  - `requested_model: "gemma4:e4b"`

This matches the exact backend `_S5F9QueuedChatRequest` model, which accepts `message` and `requested_model`, but does not accept `prompt` or `model`.

## Preserved Fallbacks

Legacy local Edge jobs remain as fallback during this migration phase:

- submit fallback: `` `${base}/jobs` ``
- poll fallback: `` `${base}/jobs/${jobId}` ``
- legacy poll fallback: `` `${base}/job/${jobId}` ``

## Polling Order

`pollJob(...)` now attempts:

1. returned `poll_url`
2. app_jobs queued chat status: `` `${base}/chat/queued/${encodeURIComponent(jobId)}` ``
3. legacy local jobs status: `` `${base}/jobs/${jobId}` ``
4. legacy singular job status: `` `${base}/job/${jobId}` ``

## Smoke Evolution

Phase 14I-U also evolves the earlier Phase 14I-S and Phase 14I-T smoke checks so they continue to pass after the expected queued-chat adapter appears in `frontend/study-ui/app.js`.

The evolved smoke behavior requires:

- the Phase 14I-U adapter marker
- `/api/chat/queued` submit/poll markers
- preserved direct `/jobs` submit/poll fallback markers

This keeps the migration safety checks current without gating or removing direct `/jobs`.

## Safety Notes

Phase 14I-U does not gate direct `/jobs`.

Phase 14I-U does not remove direct `/jobs`.

Phase 14I-U does not modify backend route behavior.

Phase 14I-U does not modify CT101.

No jobs are created by this phase.

No jobs are deleted.

No jobs are archived.

No jobs are forwarded.

Job 23 is not mutated.

No model calls are made by smoke tests.

No runtime service mutation is performed.

No raw queue summary or prompt/context dump is performed.

## Next Safe Step

Phase 14I-V should run a static and optionally browser-observed validation plan for the Study UI queued-chat adapter.

Direct `POST /jobs` and `GET /jobs` should not be gated until a later phase proves Study UI no longer depends on them.
