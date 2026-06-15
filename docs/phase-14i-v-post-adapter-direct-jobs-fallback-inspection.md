# Phase 14I-V - Post-Adapter Direct Jobs Fallback Inspection

Status: read-only inspection recorded

## Purpose

Phase 14I-V records the post-adapter validation after Phase 14I-U.

Phase 14I-U moved the Study UI companion flow to prefer the app_jobs-backed queued chat route while preserving direct local Edge `jobs` as fallback.

This phase does not change runtime behavior.

## Starting Checkpoint

- HEAD: d2c92fd
- Tag: controller-phase-14i-u-study-ui-queued-chat-adapter-2026-06-15

## Validation Result

The Study UI adapter/fallback order is valid:

- queued-chat submit is before legacy direct `/jobs` submit fallback
- queued-chat poll is before legacy direct `/jobs` poll fallback
- Study UI has exactly two `/chat/queued` references
- Study UI has exactly two direct `/jobs` fallback references
- Study UI has zero `/public/jobs` references

Observed Study UI adapter lines:

- `` `${base}/chat/queued/${encodeURIComponent(jobId)}` ``
- `` `${base}/jobs/${jobId}` ``
- `PHASE_14I_U_STUDY_UI_QUEUED_CHAT_ADAPTER`
- `` `${base}/chat/queued` ``
- `message: prompt`
- `requested_model: "gemma4:e4b"`
- `` `${base}/jobs` ``
- `job_type: "ollama_chat"`

## Remaining Direct Jobs Fallback State

Direct local Edge jobs remain present in the backend:

- `POST /jobs`
- `GET /jobs`

Study UI still references direct local Edge jobs as fallback:

- submit fallback: `` `${base}/jobs` ``
- poll fallback: `` `${base}/jobs/${jobId}` ``

Decision:

- direct `POST /jobs` and `GET /jobs` must remain enabled while Study UI fallback references exist
- direct `/jobs` is not ready to gate yet
- direct `/jobs` should only be gated after a later phase proves the Study UI no longer depends on direct `/jobs`

## Safety Notes

Phase 14I-V is read-only/static.

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

Phase 14I-W may plan the next retirement step.

Safe options:

1. Keep direct `/jobs` fallback for one more validation phase.
2. Add a feature flag around the Study UI direct `/jobs` fallback, default enabled.
3. Add a future no-fallback Study UI mode, default disabled.
4. Only after fallback removal is validated, gate direct `POST /jobs` and `GET /jobs`.
