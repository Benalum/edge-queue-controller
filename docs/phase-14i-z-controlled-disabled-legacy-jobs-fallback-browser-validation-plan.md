# Phase 14I-Z - Controlled Disabled Legacy Jobs Fallback Browser Validation Plan

Status: read-only validation plan recorded

## Purpose

Phase 14I-Z records the safe plan for a later controlled browser-observed validation of disabled Study UI legacy local Edge jobs fallback mode.

This phase does not perform the browser validation.

This phase does not flip the fallback flag globally.

This phase does not create jobs.

This phase does not call models.

This phase does not change backend route gates.

## Starting Checkpoint

- HEAD: 0b87998
- Tag: controller-phase-14i-y-disabled-frontend-legacy-jobs-fallback-validation-2026-06-15

## Current State

The Study UI has a default-enabled helper:

- `studyUiLegacyJobsFallbackEnabled()`

The optional frontend override is:

- `window.STUDY_UI_LEGACY_JOBS_FALLBACK_ENABLED`

Accepted disable values are:

- `false`
- `0`
- `"false"`
- `"0"`
- `"off"`
- `"no"`

Default behavior remains enabled.

## Controlled Browser Validation Goal

The later validation should prove that when the frontend override is disabled in a browser session:

- Study UI still prefers queued-chat submit
- Study UI still prefers queued-chat poll
- legacy `/jobs` submit fallback is not used by the frontend
- legacy `/jobs/{job_id}` poll fallback is not used by the frontend
- backend direct `POST /jobs` and `GET /jobs` remain enabled during the test
- no backend route gate is changed during the test

## Later Manual Browser Validation Procedure

The later manual validation should be performed only after a clean checkpoint.

Proposed browser-console setup before submitting a Study UI companion message:

    window.STUDY_UI_LEGACY_JOBS_FALLBACK_ENABLED = false

Expected behavior:

1. Submit a small harmless companion message from the Study UI.
2. Observe browser network requests.
3. Confirm the first submit request targets queued chat.
4. Confirm polling uses queued chat.
5. Confirm no frontend request is made to direct `/jobs` or `/jobs/{job_id}` for that request.
6. Confirm the user-facing response is handled safely.
7. If queued chat fails, capture the exact browser-visible error and stop.

## Validation Boundaries

Do not run this validation through smoke scripts.

Do not automate live job creation in smoke scripts.

Do not call model endpoints in smoke scripts.

Do not archive or delete any local jobs.

Do not mutate job 23.

Do not modify CT101.

Do not gate backend direct `/jobs` routes yet.

## Backend Route Decision

Backend direct local jobs routes stay enabled:

- `POST /jobs`
- `GET /jobs`

Reason:

The browser validation only proves frontend disabled-fallback behavior.

Backend route gating requires a later phase after disabled-mode behavior is observed and documented.

## Safety Notes

No jobs are created in this phase.

No jobs are deleted in this phase.

No jobs are archived in this phase.

No jobs are forwarded in this phase.

Job 23 is not mutated.

CT101 is not modified.

No model calls are made.

No runtime service mutation is performed.

No raw queue summary or prompt/context dump is performed.

## Next Safe Step

A later phase may perform the controlled browser-observed validation manually.

After that manual evidence is captured, another documentation phase should record:

- browser network observations
- whether `/chat/queued` worked without `/jobs`
- whether any frontend fallback still unexpectedly touched `/jobs`
- whether backend direct `/jobs` can move closer to being gated
