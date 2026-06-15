# Phase 14I-X - Study UI Legacy Jobs Fallback Flag

Status: implemented with default-enabled behavior

## Purpose

Phase 14I-X implements the Phase 14I-W plan by adding a default-enabled frontend flag around the Study UI legacy local Edge jobs fallback.

This phase does not gate backend direct `/jobs`.

## Starting Checkpoint

- HEAD: fcd72ff
- Tag: controller-phase-14i-w-study-ui-direct-jobs-fallback-flag-plan-2026-06-15

## Implementation

The Study UI now includes:

- `studyUiLegacyJobsFallbackEnabled()`
- `window.STUDY_UI_LEGACY_JOBS_FALLBACK_ENABLED`
- `PHASE_14I_X_STUDY_UI_LEGACY_JOBS_FALLBACK_FLAG`

Default behavior:

- the helper returns enabled by default
- queued-chat submit remains preferred
- queued-chat poll remains preferred
- legacy local jobs submit fallback remains available by default
- legacy local jobs poll fallback remains available by default

Explicit disable behavior:

- `window.STUDY_UI_LEGACY_JOBS_FALLBACK_ENABLED = false`
- `window.STUDY_UI_LEGACY_JOBS_FALLBACK_ENABLED = 0`
- string values `false`, `0`, `off`, or `no`

When disabled, the frontend omits:

- legacy local jobs submit fallback
- legacy local jobs poll fallback

## Preserved Backend Behavior

Direct backend routes remain enabled:

- `POST /jobs`
- `GET /jobs`

This phase does not change backend route gates.

Backend direct `/jobs` is still not ready to gate until a later phase proves Study UI can safely operate with the frontend legacy fallback disabled.

## Preserved Frontend Behavior

The default frontend behavior remains safe because legacy jobs fallback is still enabled unless explicitly disabled.

Study UI still prefers:

- submit: `` `${base}/chat/queued` ``
- poll: `` `${base}/chat/queued/${encodeURIComponent(jobId)}` ``

Study UI still retains fallback markers:

- submit fallback: `` `${base}/jobs` ``
- poll fallback: `` `${base}/jobs/${jobId}` ``
- legacy singular poll fallback: `` `${base}/job/${jobId}` ``

## Smoke Evolution

Phase 14I-X also evolves the Phase 14I-W smoke so the earlier flag plan remains valid after the helper is implemented.

## Safety Notes

No jobs are created.

No jobs are deleted.

No jobs are archived.

No jobs are forwarded.

Job 23 is not mutated.

CT101 is not modified.

No model calls are made by smoke tests.

No runtime service mutation is performed.

No raw queue summary or prompt/context dump is performed.

## Next Safe Step

Phase 14I-Y may perform a static validation plan for the disabled frontend fallback mode.

That next phase should remain read-only/static unless explicitly approved.
