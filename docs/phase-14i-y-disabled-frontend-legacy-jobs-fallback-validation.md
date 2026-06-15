# Phase 14I-Y - Disabled Frontend Legacy Jobs Fallback Validation

Status: read-only/static validation recorded

## Purpose

Phase 14I-Y records static proof that the Study UI legacy local Edge `jobs` fallback can be disabled through the Phase 14I-X frontend flag.

This phase does not flip the flag globally.

This phase does not remove fallback code.

This phase does not gate backend direct `/jobs`.

## Starting Checkpoint

- HEAD: 3e9d495
- Tag: controller-phase-14i-x-study-ui-legacy-jobs-fallback-flag-2026-06-15

## Static Validation Result

The frontend helper exists:

- `studyUiLegacyJobsFallbackEnabled()`

The frontend override exists:

- `window.STUDY_UI_LEGACY_JOBS_FALLBACK_ENABLED`

Accepted disable values are:

- `false`
- `0`
- `"false"`
- `"0"`
- `"off"`
- `"no"`

The default remains enabled because the helper returns `true` unless one of the explicit disable values is present.

## Guarded Fallback Blocks

The Study UI contains two guarded legacy fallback blocks:

1. Poll fallback guard:

- `if (studyUiLegacyJobsFallbackEnabled())`
- `` paths.push(`${base}/jobs/${jobId}`); ``
- `` paths.push(`${base}/job/${jobId}`); ``

2. Submit fallback guard:

- `if (studyUiLegacyJobsFallbackEnabled())`
- `` url: `${base}/jobs` ``
- `body: { job_type: "ollama_chat", prompt, requested_model: "gemma4:e4b" }`

## Ordering

Queued-chat remains preferred:

- queued-chat submit remains before legacy `/jobs` submit fallback
- queued-chat poll remains before legacy `/jobs` poll fallback

## Backend State

Backend direct jobs routes remain enabled:

- `POST /jobs`
- `GET /jobs`

The backend app_jobs queued-chat route remains enabled:

- `POST /api/chat/queued`
- `GET /api/chat/queued/{job_id}`

Decision:

- backend `POST /jobs` and `GET /jobs` still remain enabled
- do not flip the frontend fallback flag off globally yet
- do not gate backend direct `/jobs` yet

## Important Limitation

No live browser validation was performed in Phase 14I-Y.

No job was created.

No model call was made.

No runtime route was called.

This phase proves only static readiness for a later controlled browser-observed validation.

## Safety Notes

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

Phase 14I-Z may plan a controlled browser-observed validation of disabled frontend legacy jobs fallback mode.

That later phase should still keep backend direct `/jobs` enabled until disabled-mode behavior is proven safely.
