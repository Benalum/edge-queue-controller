# Phase 14I-M - Gate Legacy Companion Local Job Creation

Status: Companion legacy local job creation gate added

## Purpose

Phase 14I-M wires the old Companion local Edge job creation routes to the Phase 14I-K helper:

- `_phase14ik_legacy_companion_local_job_create_enabled()`

This gates the legacy route family that still creates local Edge `jobs` through `_public_create_ollama_job(...)`.

## Scope

Allowed:

- Gate legacy Companion local job creation
- Preserve default behavior
- Add documentation
- Add static/read-only smoke coverage
- Evolve Phase 14I-K and Phase 14I-L smokes so they accept this expected wiring step

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

- HEAD: 7dee033
- Tag: controller-phase-14i-l-gate-legacy-local-queue-status-2026-06-15

## Route Family Gated

The legacy Companion local job creation route family is now gated:

- `POST /public/companion/chat`
- `POST /api/companion/chat`

These routes previously called `_public_create_ollama_job(...)` directly.

## Backing Flag

The backing flag is:

- `EDGE_LEGACY_COMPANION_LOCAL_JOB_CREATE_ENABLED`

Default remains enabled.

Therefore current runtime behavior remains unchanged unless the flag is explicitly set to a disabled value in a later controlled deployment step.

## Disabled Compatibility Response

When disabled, the route returns a compatibility response instead of creating a local Edge `jobs` row.

The response identifies:

- `legacy_companion_local_job_create_disabled`
- `legacy_local_jobs_disabled_phase_14i_m`
- `legacy_companion_local_job_create_enabled: false`

## Preserved Route

`/api/chat/queued` is not changed by Phase 14I-M.

`/api/chat/queued` remains the app_jobs-oriented queued chat route and must not be retired with legacy local Edge `jobs` surfaces.

## Stale Job 23 Policy

Job 23 is not mutated.

Job 23 is not forwarded to CT101.

Job 23 remains a known legacy local Edge queue marker until a later admin-only archive/report phase.

## Definition of Done

Phase 14I-M is complete when:

- The Companion local job creation gate marker exists.
- The Companion helper is wired only to the legacy Companion local job creation route family.
- `/api/chat/queued` remains untouched.
- Phase 14I-K smoke still passes after expected evolution.
- Phase 14I-L smoke still passes after expected evolution.
- Phase 14I-M smoke passes.
- Compile passes.
- Commit, tag, and push complete.
