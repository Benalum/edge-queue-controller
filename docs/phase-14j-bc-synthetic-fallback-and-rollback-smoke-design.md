# Phase 14J-BC synthetic fallback and rollback smoke design

Phase 14J-BC defines the synthetic smoke design required before any future persistent lane worker activation.

This phase is documentation and smoke only.

## Starting checkpoint

- Base checkpoint: `8b900fe`
- Base tag: `controller-phase-14j-bb-no-lane-fallback-and-rollback-evidence-checkpoint-2026-06-15`
- Phase 14J-BB status: complete, verified, tagged, pushed
- Repository state before 14J-BC: clean

## Purpose

The project needs synthetic smoke coverage before any future activation can be considered.

The synthetic smoke design must prove:

1. disabled gate behavior remains equivalent to current behavior
2. no-lane jobs preserve the primary/default path
3. lane-tagged jobs can select a matching lane worker only in isolated synthetic helper tests
4. lane-tagged jobs do not strand when lane workers are unavailable unless the job explicitly denies fallback
5. rollback restores disabled-gate behavior
6. rollback does not require CT101 mutation
7. rollback does not require live model calls
8. rollback does not mutate production jobs

## Required synthetic smoke cases

A later smoke artifact phase should include pure/in-process helper tests for:

| Case | Gate | Job | Worker set | Expected result |
| --- | --- | --- | --- | --- |
| disabled_equivalence | disabled | lane-tagged | primary + lane | original worker list preserved |
| no_lane_primary | enabled in-process only | no-lane normal job | primary + lane | primary remains eligible |
| lane_match | enabled in-process only | lane job requiring lane worker | primary + matching lane | matching lane worker selected |
| lane_missing_with_fallback | enabled in-process only | lane job allowing fallback | primary only | primary remains available if helper contract allows fallback |
| lane_missing_no_fallback | enabled in-process only | lane job denying fallback | primary only | no eligible workers |
| disabled_rollback | disabled after enabled in-process test | lane-tagged | primary + lane | original worker list restored |

The in-process enabled cases must only set environment inside a temporary Python process or subshell. They must not change service environment, systemd drop-ins, shell profile files, or controller runtime state.

## Rollback smoke design

A future rollback smoke must verify, without mutating live services unless separately approved:

- `EDGE_PERSISTENT_LANE_WORKERS_ENABLED` is absent or false
- `_phase14j_lane_workers_enabled()` returns false
- `_phase14j_filter_workers_for_lane(workers, job)` returns the original list
- worker registry has no lane-enabled workers
- no non-empty `worker_lane` values exist
- no non-primary `worker_role` values exist
- controller-only local health returns `200`
- CT101 is not called
- no live model endpoint is called
- no production job row is changed

## Current observed evidence from BB/BA

- Worker registry remains empty/default-off.
- Controller jobs table remains inspectable.
- All sampled controller jobs were no-lane jobs.
- No sampled jobs deny primary fallback.
- Controller service is active.
- Controller-only local health returns `200`.
- Persistent lane worker flag remains absent or disabled.

## Hard boundaries

This phase does not:

- change `edge_controller.py`
- change `/workers/heartbeat`
- change worker registration SQL
- change `WorkerHeartbeatRequest`
- rerun `ops/db/apply-default-off-worker-registry-lane-metadata.sh`
- enable `EDGE_PERSISTENT_LANE_WORKERS_ENABLED`
- restart or reload services
- call CT101
- call live model endpoints
- mutate job 23
- mutate any production job
- activate scheduler lane dispatch
- activate primary-worker filtering
- enable router model selection
- expose router output
- start warmup execution
- start persistent lane workers
- create lane worker services
- change service environment drop-ins

Synthetic smoke design is not runtime activation. In-process helper testing is not service activation. Rollback design is not rollback execution.

## Remaining blockers

- `persistent_lane_workers_not_active`
- `primary_worker_unfiltered`
- `scheduler_lane_dispatch_not_active`
- `ct101_runtime_protected`
- `router_rollout_parked`
- `warmup_execution_disabled`
- `fallback_worker_contract_pending`
- `rollback_smoke_pending`
- `synthetic_enabled_lane_smoke_pending`
- `activation_approval_required`

## Recommended next safe phase

Recommended next safe phase:

- Phase 14J-BD: synthetic fallback and rollback smoke artifact, smoke-only/no runtime activation

That phase may add a focused smoke artifact with pure/in-process helper tests. It must not enable persistent lane workers in the service environment, dispatch lanes, filter primary workers at runtime, call CT101, call models, mutate jobs, restart services, or change service environment drop-ins.
