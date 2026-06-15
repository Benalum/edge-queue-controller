# Phase 14I-O - Remaining Legacy Local Jobs Read/List Route Inspection

Status: read-only inspection recorded

## Purpose

Phase 14I-O records the static route-shape inspection after Phase 14I-N.

This phase does not change runtime behavior.

## Starting Checkpoint

- HEAD: 5877774
- Tag: controller-phase-14i-n-gate-legacy-public-local-jobs-creation-2026-06-15

## Confirmed Legacy Local Jobs Routes

The following legacy local Edge `jobs` routes still exist:

- `POST /jobs`
- `GET /jobs`
- `GET /public/jobs/{job_id}`
- `GET /public/jobs`

The following legacy creation routes are already gated:

- `POST /public/jobs`
- `POST /public/companion/chat`
- `POST /api/companion/chat`

The app_jobs queued chat route remains preserved:

- `POST /api/chat/queued`
- `GET /api/chat/queued/{job_id}`

## Helper Counts Observed

Expected helper usage after Phase 14I-N:

- `_phase14ik_legacy_local_jobs_routes_enabled(` count: 2
- `_phase14ik_legacy_companion_local_job_create_enabled(` count: 2
- `_phase14ik_legacy_local_queue_status_enabled(` count: 2
- `_phase14ik_legacy_local_jobs_admin_archive_enabled(` count: 1

## Local Job Create Helper Count

`_public_create_ollama_job(` count is expected to be 3 after Phase 14I-N:

- helper function definition
- legacy public jobs creation route
- legacy Companion local job creation route

## Safety Notes

Phase 14I-O is read-only/static.

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

Phase 14I-P can gate the remaining legacy local jobs read/list route family behind `EDGE_LEGACY_LOCAL_JOBS_ROUTES_ENABLED`, with default behavior unchanged.

Candidate route family for Phase 14I-P:

- `GET /public/jobs/{job_id}`
- `GET /public/jobs`

The direct internal routes `POST /jobs` and `GET /jobs` should be handled separately after another static inspection of whether they are admin/internal-only, public, or test-only.
