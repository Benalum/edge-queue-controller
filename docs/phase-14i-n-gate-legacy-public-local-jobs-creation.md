# Phase 14I-N - Gate Legacy Public Local Jobs Creation

Status: public legacy local jobs creation gate added

## Purpose

Phase 14I-N wires the old public local Edge job creation route to the Phase 14I-K helper:

- `_phase14ik_legacy_local_jobs_routes_enabled()`

This gates the legacy route that still creates local Edge `jobs` through `_public_create_ollama_job(...)`.

## Scope

Allowed:

- Gate legacy public local jobs creation
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

- HEAD: f30f4af
- Tag: controller-phase-14i-m-gate-legacy-companion-local-job-creation-2026-06-15

## Route Family Gated

The legacy public local jobs creation route is now gated:

- `POST /public/jobs`

This route previously called `_public_create_ollama_job(...)` directly.

## Backing Flag

The backing flag is:

- `EDGE_LEGACY_LOCAL_JOBS_ROUTES_ENABLED`

Default remains enabled.

Therefore current runtime behavior remains unchanged unless the flag is explicitly set to a disabled value in a later controlled deployment step.

## Disabled Compatibility Response

When disabled, the route returns a compatibility response instead of creating a local Edge `jobs` row.

The response identifies:

- `legacy_public_local_jobs_create_disabled`
- `legacy_local_jobs_disabled_phase_14i_n`
- `legacy_local_jobs_routes_enabled: false`

## Preserved Route

`/api/chat/queued` is not changed by Phase 14I-N.

`/api/chat/queued` remains the app_jobs-oriented queued chat route and must not be retired with legacy local Edge `jobs` surfaces.

## Stale Job 23 Policy

Job 23 is not mutated.

Job 23 is not forwarded to CT101.

Job 23 remains a known legacy local Edge queue marker until a later admin-only archive/report phase.

## Definition of Done

Phase 14I-N is complete when:

- The public local jobs creation gate marker exists.
- The public local jobs helper is wired only to the legacy public local jobs creation route.
- `/api/chat/queued` remains untouched.
- Phase 14I-K smoke still passes after expected evolution.
- Phase 14I-L smoke still passes after expected evolution.
- Phase 14I-M smoke still passes after expected evolution.
- Phase 14I-N smoke passes.
- Compile passes.
- Commit, tag, and push complete.
