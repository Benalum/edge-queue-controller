# Phase 14J-CJ - Gate B Worker Availability Plan

PHASE_14J_CJ_GATE_B_WORKER_AVAILABILITY_PLAN

## Scope

MUTATION_SCOPE=docs_smoke_only_gate_b_worker_availability_plan

This phase plans Gate B worker availability. It does not enable runtime, does not create or mutate production worker rows, does not start CT101, does not call model/Ollama endpoints, and does not activate scheduler lane dispatch.

## Starting checkpoint

- START_HEAD=509ac7b
- START_TAG=controller-phase-14j-ci-post-ch-stability-checkpoint-and-gate-b-readiness-decision-2026-06-16
- SERVICE=edge-queue-controller.service
- service_active=active
- service_enabled=enabled
- service_EDGE_PERSISTENT_LANE_WORKERS_ENABLED=<unset>
- sqlite_quick_check=ok
- worker_counts=0,0,0,0
- jobs_summary="failed:1,forwarded:20,queued:1"

## Carried-forward result from Gate A

- GATE_A_CONTROLLER_SIDE_FLAG_TEST=passed
- CH_ROLLBACK_PERFORMED=yes
- FINAL_STATE_DEFAULT_OFF=yes
- RUNTIME_ACTIVATION_LEFT_ENABLED=no

Gate A proved that the controller-side service environment flag can be temporarily enabled and rolled back safely. Gate B must not assume that Gate A should remain enabled yet.

## Gate B objective

Gate B is about worker availability, not scheduler dispatch.

Gate B asks:

1. Which worker can become lane-capable?
2. Can worker availability be proven without CT101 mutation?
3. Can worker availability be proven without production DB mutation?
4. Can a synthetic worker availability smoke prove the lane eligibility/filter behavior safely?
5. What rollback evidence is needed before a real lane-capable worker is introduced?
6. What must remain blocked until later gates?

## Gate B recommended ladder

### Gate B0 - synthetic worker availability smoke

Status: recommended next.

This should use a temporary SQLite database, temporary rows, or pure in-memory test data. It must not mutate production `edge_queue.sqlite3`.

Goals:

- Prove the lane filter accepts a synthetic worker with:
  - worker_role set to a lane-capable role
  - worker_lane set to the requested lane
  - accepts_lane_jobs enabled
  - disabled unset or false
  - computed_health available
  - current_running_jobs below max
- Prove the lane filter rejects workers that are:
  - disabled
  - stale/unhealthy/offline
  - wrong lane
  - primary-only
  - over capacity
- Prove no-lane jobs still keep the default worker path.
- Prove lane-required jobs fail safe or defer when no lane worker is available.

Gate B0 must not call CT101, model endpoints, Ollama endpoints, scheduler runtime, or production jobs.

### Gate B1 - controller-local metadata-only worker availability plan

Status: later, after B0 passes.

This would decide whether a controller-local or synthetic non-production worker row can represent lane availability for smoke-only evidence.

This still should avoid production job mutation.

### Gate B2 - real worker registration lane availability

Status: later, explicit approval required.

This may involve CT101 or worker-side behavior. It must have a separate approval, rollback path, and service/worker evidence.

### Gate C - scheduler lane dispatch

Status: blocked.

Scheduler lane dispatch must not be enabled until worker availability is proven and rollback is tested.

### Gate D - primary-worker filtering

Status: blocked.

Primary-worker filtering must remain blocked until no-lane behavior and lane-required behavior are proven safe.

## Current hard boundaries

- DB_MUTATION=not_performed
- JOB_MUTATION=not_performed
- CT101_CALL=not_performed
- MODEL_OLLAMA_CALL=not_performed
- SCHEDULER_LANE_DISPATCH_ACTIVATION=not_performed
- PRIMARY_WORKER_FILTERING_ACTIVATION=not_performed
- PERSISTENT_LANE_WORKER_STARTUP=not_performed
- ROUTER_ROLLOUT=not_performed
- WARMUP_EXECUTION=not_performed
- DO_NOT_RERUN_14J_AG_APPLY_WRAPPER=preserved

## Gate B0 required smoke shape

The next safe implementation phase should create a focused smoke artifact that:

1. Does not read secrets.
2. Does not print full service environment.
3. Does not mutate production DB.
4. Uses a temporary database or in-memory fixtures.
5. Imports or exercises only the controller lane filtering helpers if safe.
6. Verifies the actual helper names discovered in BL/CG:
   - _phase14j_lane_workers_enabled
   - _phase14j_filter_workers_for_lane
7. Proves default-off behavior when the service flag is unset.
8. Proves enabled behavior only under a local test environment override.
9. Does not restart services.
10. Does not create production jobs.

## Security follow-up

SECURITY_FOLLOWUP_REQUIRED=rotate_exposed_smtp_credential

A prior diagnostic exposed an SMTP password from a systemd drop-in. Do not print full systemd drop-in contents again. Rotate the credential in a separate guarded security-maintenance phase.

## CJ decision

NEXT_SAFE_PHASE=gate_b0_synthetic_worker_availability_smoke_artifact

CI and CJ recommend Gate B0 synthetic worker availability smoke before any real worker availability mutation.
