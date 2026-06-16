# Phase 14J-BK - Runtime Activation Preflight Checklist and Rollback Verification Plan

Status: docs/smoke-only checkpoint.  
Checkpoint base: Phase 14J-BJ at `87dad82`.  
This phase does not activate lane workers, scheduler lane dispatch, primary-worker filtering, router rollout, warmup execution, CT101 runtime behavior, live model calls, or production job mutation.

## Purpose

Phase 14J-BK converts the post-14J-BJ safety state into an activation preflight checklist and rollback verification plan.

The goal is to make the next runtime-adjacent lane-worker work safer by defining what must be true before activation is even considered. BK is not activation approval.

## New-chat bootstrap evidence recorded for BK

A read-only bootstrap/system check was run before this docs/smoke-only phase.

Observed passing facts:

- repository was clean
- `HEAD=87dad82`
- `origin/main=87dad82`
- remote `main=87dad82`
- latest tag `controller-phase-14j-bj-rollback-safety-docs-and-smoke-artifact-2026-06-16` existed locally and remotely
- `edge_controller.py` compiled in memory
- `edge-queue-controller` was active
- controller-only local health returned HTTP 200
- SQLite `PRAGMA quick_check` returned `ok`
- worker metadata table was `workers`
- canonical worker lane metadata columns were present:
  - `worker_role`
  - `worker_lane`
  - `accepts_lane_jobs`
  - `capabilities`
  - `disabled`
  - `current_running_jobs`
  - `state`
  - `computed_health`
- `disabled_reason` was absent and is not part of the canonical Phase 14J lane metadata schema
- worker default-off counts were:
  - `worker_count=0`
  - `lane_enabled_worker_count=0`
  - `non_default_worker_lane_count=0`
  - `non_primary_worker_role_count=0`
- `EDGE_PERSISTENT_LANE_WORKERS_ENABLED` was absent in shell and service environment
- no schema wrapper rerun occurred
- no service restart/reload occurred
- no CT101, Ollama, or live model endpoint call occurred
- no job 23 or production job mutation occurred
- no scheduler lane dispatch, primary-worker filtering, router rollout, warmup execution, or persistent lane worker activation occurred

## Activation remains blocked

Activation remains blocked after BK.

Current blockers:

- `persistent_lane_workers_not_active`
- `primary_worker_unfiltered`
- `scheduler_lane_dispatch_not_active`
- `ct101_runtime_protected`
- `router_rollout_parked`
- `warmup_execution_disabled`
- `runtime_activation_approval_required`
- `rollback_runtime_evidence_pending`

## Hard boundaries preserved by BK

- Do not rerun `ops/db/apply-default-off-worker-registry-lane-metadata.sh`.
- Do not enable `EDGE_PERSISTENT_LANE_WORKERS_ENABLED`.
- Do not restart or reload services unless a later phase explicitly asks and the user approves.
- Do not call CT101, live model endpoints, or Ollama endpoints.
- Do not mutate job 23 or any production job.
- Do not activate scheduler lane dispatch.
- Do not activate primary-worker filtering.
- Do not activate router model selection.
- Do not activate warmup execution.
- Do not activate persistent lane workers.
- Do not use PPB for runtime-adjacent or red tasks.

## Lane behavior contract that must not regress

The current safe contract remains:

1. No-lane jobs keep the primary/default worker path.
2. Lane-tagged jobs requiring a lane worker do not silently fall back to primary.
3. Lane-tagged jobs with no eligible matching lane worker remain blocked/deferred.
4. `allow_primary_fallback=true` does not change production behavior yet.
5. Any later fallback behavior change must be explicit, documented, smoked, and approved.

## Required preflight checklist before any future activation phase

A later runtime-adjacent activation phase must prove all of the following before changing runtime behavior:

1. Source documents are current through the latest pushed checkpoint.
2. New-chat bootstrap passes at the current checkpoint.
3. Repo is clean.
4. `HEAD` matches `origin/main`.
5. Current focused smoke passes.
6. Current regression smoke chain passes.
7. SQLite `PRAGMA quick_check` returns `ok`.
8. Worker metadata canonical 8 columns are present.
9. Worker default-off counts are understood and intentionally handled.
10. `EDGE_PERSISTENT_LANE_WORKERS_ENABLED` is absent/disabled before activation.
11. No unexpected worker rows exist before activation.
12. No production job mutation is required for activation.
13. No job 23 mutation is required.
14. No CT101 mutation is required unless separately approved.
15. No live model/Ollama endpoint call is required unless separately approved.
16. No service reload/restart occurs without explicit user approval.
17. The no-lane primary/default path has a verification plan.
18. The lane-missing strict/defer behavior has a verification plan.
19. The lane-match behavior has a verification plan.
20. A rollback path exists and is tested as far as possible before activation.

## Rollback verification plan for later runtime-adjacent work

A later activation phase must include a rollback plan that can be run quickly if activation causes unexpected behavior.

Minimum rollback plan:

1. Restore persistent lane worker flag to absent/disabled.
2. Remove or disable any activation-specific systemd drop-in created by the activation phase.
3. Reload/restart only if that later phase explicitly has approval for service control.
4. Verify service returns to active/running.
5. Verify local controller health returns HTTP 200 if allowed by the phase.
6. Verify SQLite `PRAGMA quick_check` returns `ok`.
7. Verify worker metadata columns still exist.
8. Verify lane-enabled worker count returns to expected default-off value.
9. Verify no-lane primary/default path remains available.
10. Verify lane-tagged missing-worker jobs do not silently fall back to primary.
11. Capture rollback evidence in a docs artifact.
12. Run focused rollback smoke.
13. Run regression smoke chain.
14. Commit/tag/push rollback evidence only after smokes pass.

## Future activation-phase design requirement

Before enabling persistent lane workers, create a separate phase that documents:

- exact service/drop-in environment delta
- exact rollback command sequence
- expected pre-activation worker counts
- expected post-activation worker counts
- expected scheduler behavior while lane dispatch remains disabled
- expected no-lane behavior
- expected lane-tagged missing-worker behavior
- exact evidence to capture before and after service control
- explicit approval phrase required before service reload/restart

## BK conclusion

Phase 14J-BK is a docs/smoke-only preflight checkpoint.

It improves readiness for future runtime-adjacent work but does not approve or perform activation. Runtime changes remain serialized and approval-gated.
