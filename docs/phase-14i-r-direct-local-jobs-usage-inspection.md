# Phase 14I-R - Direct Local Jobs Usage Inspection

Status: read-only inspection recorded

## Purpose

Phase 14I-R records repo usage of the direct local Edge `jobs` routes after Phase 14I-Q.

This phase does not change runtime behavior.

## Starting Checkpoint

- HEAD: 0c5d3f0
- Tag: controller-phase-14i-q-direct-local-jobs-route-inspection-2026-06-15

## Initial Scan Result

The broad repo scan was too noisy because historical archives, generated docs, backup files, and old smoke scripts produced thousands of `/jobs` matches.

The broad scan still confirmed:

- Working tree remained clean.
- Route definition counts remained correct.
- No live endpoint calls were made.

## Focused Active Caller Result

The focused active-code scan found one real active caller file:

- `frontend/study-ui/app.js`

Direct local `/jobs` usage in that file:

- `pollJob(...)` includes fallback polling path: `` `${base}/jobs/${jobId}` ``
- `sendCompanionToApi(...)` submits queued companion work to: `` `${base}/jobs` ``

## Classification

The direct `/jobs` routes are still active through the Study UI companion flow.

Therefore, `POST /jobs` and `GET /jobs` should not be gated yet.

## Current Route State

The following direct local jobs routes remain ungated:

- `POST /jobs`
- `GET /jobs`

The following public legacy local jobs routes are already gated with default behavior preserved:

- `POST /public/jobs`
- `GET /public/jobs/{job_id}`
- `GET /public/jobs`

The following app_jobs-backed route remains preserved:

- `POST /api/chat/queued`
- `GET /api/chat/queued/{job_id}`

## Safety Notes

Phase 14I-R is read-only/static.

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

Before gating direct `/jobs`, the Study UI companion flow must be handled.

Safe future options:

1. Migrate `frontend/study-ui/app.js` companion submission to `/api/chat/queued`.
2. Preserve direct `/jobs` until Study UI companion is retired or replaced.
3. Add a disabled-by-default compatibility plan, but do not flip it until the Study UI caller is migrated.

## Next Safe Step

Phase 14I-S should inspect and document the Study UI companion queue path migration plan.

Candidate Phase 14I-S scope:

- Inspect `frontend/study-ui/app.js` companion submit/poll flow.
- Compare `/jobs` response shape to `/api/chat/queued` response shape.
- Plan a safe migration with no live runtime calls.
- Do not modify frontend behavior yet unless a later gated implementation phase is approved.
