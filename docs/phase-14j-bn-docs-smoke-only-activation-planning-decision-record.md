# Phase 14J-BN - Docs/Smoke-Only Activation Planning Decision Record

PHASE_14J_BN_ACTIVATION_DECISION_RECORD

Date: 2026-06-16

## Scope

MUTATION_SCOPE=docs_smoke_only

This phase records the next activation-planning decision after the Phase 14J-BL read-only activation-surface inspection and the new-chat read-only bootstrap.

This phase is not runtime activation.

## Non-activation confirmations

RUNTIME_ACTIVATION=not_performed  
SERVICE_RESTART_RELOAD=not_performed  
CT101_MODEL_OLLAMA_CALLS=forbidden  
CT101_MODEL_JOB_MUTATION=not_performed  
DB_MUTATION=not_performed  
JOB_MUTATION=not_performed  
LANE_WORKER_ENABLEMENT=not_performed  
SCHEDULER_LANE_DISPATCH_ACTIVATION=not_performed  
PRIMARY_WORKER_FILTERING_ACTIVATION=not_performed  
ROUTER_MODEL_SELECTION_ACTIVATION=not_performed  
WARMUP_EXECUTION_ACTIVATION=not_performed  

DO_NOT_RERUN_14J_AG_APPLY_WRAPPER

The Phase 14J-AG wrapper `ops/db/apply-default-off-worker-registry-lane-metadata.sh` must not be rerun.

## Current decision

ACTIVATION_DECISION=blocked_pending_explicit_approval

Persistent lane worker runtime activation remains blocked.

The project should not enable `EDGE_PERSISTENT_LANE_WORKERS_ENABLED`, scheduler lane dispatch, or primary-worker filtering in this phase.

EDGE_PERSISTENT_LANE_WORKERS_ENABLED=must_remain_absent_or_disabled

## Current trusted activation surface

The actual current Phase 14J helper names are:

- `_phase14j_lane_workers_enabled`
- `_phase14j_default_off_worker_registration_metadata`
- `_phase14j_job_lane_metadata`
- `_phase14j_worker_lane_metadata`
- `_phase14j_worker_eligible_for_job`
- `_phase14j_filter_workers_for_lane`

Important current behavior:

- `_phase14j_lane_workers_enabled()` reads the persistent lane worker gate.
- Scheduler filtering remains gated by `phase14j_lane_scheduler_gate_enabled = _phase14j_lane_workers_enabled()`.
- The scheduler lane filter call is `workers = _phase14j_filter_workers_for_lane(workers, job)`.
- When the lane gate is disabled, lane filtering preserves the original worker list.
- Worker registration uses `_phase14j_default_off_worker_registration_metadata()`.
- The disabled-gate reason marker is `"reason_code": "lane_gate_disabled"`.

## Current blockers

- `persistent_lane_workers_not_active`
- `primary_worker_unfiltered`
- `scheduler_lane_dispatch_not_active`
- `ct101_runtime_protected`
- `router_rollout_parked`
- `warmup_execution_disabled`
- `runtime_activation_approval_required`
- `rollback_runtime_evidence_pending`

## Required evidence before any later runtime activation

Before any runtime activation phase can be proposed, the project needs a separate read-only or docs/smoke-only evidence phase that confirms:

1. Repository is clean and current.
2. Source docs are current.
3. Existing BL and BN smokes pass.
4. SQLite read-only `PRAGMA quick_check` returns `ok`.
5. Worker registry metadata remains default-off.
6. Persistent lane worker flag is absent/disabled in shell and service.
7. Rollback command path is documented.
8. Rollback verification smoke exists.
9. Service restart/reload impact is explicitly scoped.
10. CT101/model/Ollama/job/DB mutation remains prohibited unless a later phase explicitly approves it.

ROLLBACK_RUNTIME_EVIDENCE=pending

## Recommended next phase

NEXT_SAFE_PHASE=phase_14j_bo_read_only_runtime_rollback_evidence

The next safe phase should be read-only runtime rollback evidence collection or another docs/smoke-only planning checkpoint.

Phase 14J-BO should not activate runtime. It should only inspect and document what would be needed to safely activate and roll back later.

## Explicit approval boundary

A future runtime activation phase requires explicit user approval.

Approval must name the phase and must explicitly allow the bounded runtime change. Without that approval, the following remain blocked:

- enabling persistent lane workers
- scheduler lane dispatch activation
- primary-worker filtering activation
- service reload/restart
- CT101/model/Ollama calls
- production job mutation
- DB mutation
- router rollout
- warmup execution
