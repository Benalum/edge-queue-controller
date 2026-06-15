# Phase 14I-P - Gate Public Legacy Local Jobs Read/List Routes

Status: public legacy local jobs read/list gates added

## Purpose

Phase 14I-P gates the public legacy local Edge `jobs` read/list route family behind the existing Phase 14I-K helper:

- `_phase14ik_legacy_local_jobs_routes_enabled()`

This follows Phase 14I-N, which gated the public legacy local jobs creation route.

## Scope

Allowed:

- Gate public legacy local jobs read route
- Gate public legacy local jobs list route
- Preserve default behavior
- Add documentation
- Add static/read-only smoke coverage
- Evolve earlier smokes so they accept this expected wiring step

Blocked:

- Job creation
- Job deletion
- Job archival
- Job forwarding
- Worker activation
- CT101 mutation
- Router rollout
- Warmup execution
- Model generate/chat calls
- Runtime service mutation
- Power automation mutation
- Raw prompt/context dumping
- Any change to `/api/chat/queued`

## Starting Checkpoint

- HEAD: 16f6e64
- Tag: controller-phase-14i-o-remaining-legacy-local-jobs-read-list-route-inspection-2026-06-15

## Route Family Gated

The following public legacy local jobs read/list routes are now gated:

- `GET /public/jobs/{job_id}`
- `GET /public/jobs`

The public legacy local jobs creation route was already gated in Phase 14I-N:

- `POST /public/jobs`

## Backing Flag

The backing flag is:

- `EDGE_LEGACY_LOCAL_JOBS_ROUTES_ENABLED`

Default remains enabled.

Therefore current runtime behavior remains unchanged unless the flag is explicitly set to a disabled value in a later controlled deployment step.

## Disabled Compatibility Responses

When disabled, `GET /public/jobs/{job_id}` returns:

- `legacy_public_local_jobs_read_disabled`
- `legacy_local_jobs_disabled_phase_14i_p`
- `legacy_local_jobs_routes_enabled: false`

When disabled, `GET /public/jobs` returns:

- `legacy_public_local_jobs_list_disabled`
- `legacy_local_jobs_disabled_phase_14i_p`
- `legacy_local_jobs_routes_enabled: false`
- `count: 0`
- `jobs: []`

## Preserved Route

`/api/chat/queued` is not changed by Phase 14I-P.

`/api/chat/queued` remains the app_jobs-oriented queued chat route and must not be retired with legacy local Edge `jobs` surfaces.

## Stale Job 23 Policy

Job 23 is not mutated.

Job 23 is not forwarded to CT101.

Job 23 remains a known legacy local Edge queue marker until a later admin-only archive/report phase.

## Remaining Legacy Routes

The direct internal local jobs routes still remain for later analysis:

- `POST /jobs`
- `GET /jobs`

These should be handled separately after confirming whether they are admin/internal-only, public, or test-only.

## Definition of Done

Phase 14I-P is complete when:

- The public local jobs read gate marker exists.
- The public local jobs list gate marker exists.
- The public local jobs helper count is updated to 4.
- `/api/chat/queued` remains untouched.
- Phase 14I-K smoke still passes after expected evolution.
- Phase 14I-L smoke still passes after expected evolution.
- Phase 14I-M smoke still passes after expected evolution.
- Phase 14I-N smoke still passes after expected evolution.
- Phase 14I-O smoke still passes after expected evolution.
- Phase 14I-P smoke passes.
- Compile passes.
- Commit, tag, and push complete.
