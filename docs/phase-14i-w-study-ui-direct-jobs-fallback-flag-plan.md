# Phase 14I-W - Study UI Direct Jobs Fallback Flag Plan

Status: read-only flag plan recorded

## Purpose

Phase 14I-W records the safe plan for adding a default-enabled frontend flag around the Study UI direct local Edge `jobs` fallback.

This phase does not change runtime behavior.

## Starting Checkpoint

- HEAD: cc98067
- Tag: controller-phase-14i-v-post-adapter-direct-jobs-fallback-inspection-2026-06-15

## Current State

Phase 14I-U already changed the Study UI companion flow so the app_jobs-backed queued chat route is preferred.

Current preferred queued-chat paths:

- submit: `` `${base}/chat/queued` ``
- poll: `` `${base}/chat/queued/${encodeURIComponent(jobId)}` ``

Current legacy fallback paths remain:

- submit fallback: `` `${base}/jobs` ``
- poll fallback: `` `${base}/jobs/${jobId}` ``
- legacy singular poll fallback: `` `${base}/job/${jobId}` ``

Current ordering is correct:

- queued-chat submit comes before legacy direct `/jobs` submit fallback
- queued-chat poll comes before legacy direct `/jobs` poll fallback

## Flag Plan

A later implementation phase may add a default-enabled Study UI helper:

- `studyUiLegacyJobsFallbackEnabled()`

Proposed global override:

- `window.STUDY_UI_LEGACY_JOBS_FALLBACK_ENABLED`

Default behavior:

- enabled by default
- preserve direct `/jobs` submit fallback
- preserve direct `/jobs` poll fallback

Proposed behavior when explicitly disabled in a later validation phase:

- omit direct `/jobs` submit fallback
- omit direct `/jobs` poll fallback
- keep `/api/chat/queued` / `/chat/queued` behavior preferred
- keep non-jobs direct chat fallbacks unchanged unless separately retired

## Backend Gate Decision

Direct backend routes remain present:

- `POST /jobs`
- `GET /jobs`

Decision:

- backend direct `POST /jobs` and `GET /jobs` are still not ready to gate
- the next implementation should only flag the frontend fallback
- backend direct `/jobs` gates should wait until a later phase proves the Study UI no longer depends on direct `/jobs`

## Safety Notes

Phase 14I-W is read-only/static.

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

Phase 14I-X may implement the default-enabled frontend helper.

Candidate Phase 14I-X scope:

1. Add `studyUiLegacyJobsFallbackEnabled()`.
2. Default to enabled.
3. Support `window.STUDY_UI_LEGACY_JOBS_FALLBACK_ENABLED` when present.
4. Wrap only the direct `/jobs` submit fallback and direct `/jobs` poll fallback.
5. Keep direct `/jobs` fallback enabled by default.
6. Do not gate backend `POST /jobs` or `GET /jobs`.
7. Evolve smokes so they prove default-enabled fallback behavior remains safe.
