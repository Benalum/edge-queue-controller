# Phase 14I-Q - Direct Local Jobs Route Inspection

Status: read-only inspection recorded

## Purpose

Phase 14I-Q records the static route-shape inspection of the direct local Edge `jobs` routes after Phase 14I-P.

This phase does not change runtime behavior.

## Starting Checkpoint

- HEAD: 83abc8b
- Tag: controller-phase-14i-p-gate-public-legacy-local-jobs-read-list-routes-2026-06-15

## Direct Local Jobs Routes Inspected

The following direct local Edge `jobs` routes still exist:

- `POST /jobs`
- `GET /jobs`

## Inspection Findings

`POST /jobs`:

- Route exists exactly once.
- Uses `CreateEdgeJobRequest`.
- Inserts into local Edge `jobs`.
- Selects from local Edge `jobs`.
- No visible Phase 14I helper gate.
- No visible auth marker.
- No visible admin marker.
- No visible user marker.

`GET /jobs`:

- Route exists exactly once.
- Selects from local Edge `jobs`.
- No visible Phase 14I helper gate.
- No visible auth marker.
- No visible admin marker.
- No visible user marker.

## Safety Notes

Phase 14I-Q is read-only/static.

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

`POST /jobs` and `GET /jobs` should not be retired or gated blindly.

They should be handled in a later phase only after confirming whether they are:

- internal-only
- admin-only
- test-only
- still used by current controller tooling
- safe to gate behind `EDGE_LEGACY_LOCAL_JOBS_ROUTES_ENABLED`

## Preserved Route

`/api/chat/queued` is not changed by Phase 14I-Q.

`/api/chat/queued` remains the app_jobs-oriented queued chat route and must not be retired with legacy local Edge `jobs` surfaces.

## Next Safe Step

Phase 14I-R can inspect references/usages of the direct `/jobs` routes in the repo before deciding whether to gate them.

Candidate Phase 14I-R scope:

- Search frontend/backend/scripts/docs for `/jobs` usage.
- Classify each usage as public, internal, test, smoke, or obsolete.
- Do not mutate runtime behavior.
- Do not call live endpoints.
