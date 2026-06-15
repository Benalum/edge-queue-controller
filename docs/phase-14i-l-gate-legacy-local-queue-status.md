# Phase 14I-L - Gate Legacy Local Queue Status

Status: queue status gate added

## Purpose

Phase 14I-L wires the read-only legacy local Edge queue-status endpoint to the Phase 14I-K helper:

- `_phase14ik_legacy_local_queue_status_enabled()`

This is the first route-family wiring step for the local Edge `jobs` retirement plan.

## Scope

Allowed:

- Gate legacy local queue-status behavior
- Preserve default behavior
- Add documentation
- Add static/read-only smoke coverage
- Evolve Phase 14I-K smoke so it accepts this expected wiring step

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

- HEAD: d13b455
- Tag: controller-phase-14i-k-disabled-legacy-local-edge-jobs-flag-helpers-2026-06-15

## Route Family Gated

The route function `public_chat_queue_status` now checks:

- `_phase14ik_legacy_local_queue_status_enabled()`

When the flag is disabled, it returns a compatibility response instead of reporting the legacy local Edge `jobs` queue as the active chat queue.

## Backing Flag

The backing flag is:

- `EDGE_LEGACY_LOCAL_QUEUE_STATUS_ENABLED`

Default remains enabled.

Therefore current runtime behavior remains unchanged unless the flag is explicitly set to a disabled value in a later controlled deployment step.

## Preserved Route

`/api/chat/queued` is not changed by Phase 14I-L.

`/api/chat/queued` remains the app_jobs-oriented queued chat route and must not be retired with legacy local Edge `jobs` surfaces.

## Stale Job 23 Policy

Job 23 is not mutated.

Job 23 is not forwarded to CT101.

Job 23 remains a known legacy local Edge queue marker until a later admin-only archive/report phase.

## Definition of Done

Phase 14I-L is complete when:

- The queue status gate marker exists.
- The queue status helper is wired only to the legacy queue-status route family.
- `/api/chat/queued` remains untouched.
- Phase 14I-K smoke still passes after expected evolution.
- Phase 14I-L smoke passes.
- Compile passes.
- Commit, tag, and push complete.
