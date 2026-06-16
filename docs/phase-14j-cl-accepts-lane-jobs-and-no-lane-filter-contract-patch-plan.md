# Phase 14J-CL - accepts_lane_jobs and No-Lane Filter Contract Patch Plan

PHASE_14J_CL_ACCEPTS_LANE_JOBS_AND_NO_LANE_FILTER_CONTRACT_PATCH_PLAN

## Scope

MUTATION_SCOPE=docs_smoke_only_contract_patch_plan

This phase plans the patch after Phase 14J-CK found Gate B0 worker availability gaps.

No source code is patched in CL. No runtime is activated.

## Starting checkpoint

- START_HEAD=4fa1799
- START_TAG=controller-phase-14j-ck-gate-b0-synthetic-worker-availability-smoke-artifact-2026-06-16
- SERVICE=edge-queue-controller.service
- service_active=active
- service_EDGE_PERSISTENT_LANE_WORKERS_ENABLED=<unset>
- sqlite_quick_check=ok
- worker_counts=0,0,0,0

## CK findings carried forward

- GATE_B0_RESULT=blocked_by_accepts_lane_jobs_gap_and_no_lane_contract_clarification
- ACCEPTS_LANE_JOBS_FALSE_REJECTION_GAP=observed
- NO_LANE_ENABLED_GATE_ELIGIBILITY_PRUNING=observed
- NO_LANE_FULL_LIST_PASSTHROUGH_NOT_VERIFIED=observed

## Patch contract decision

PATCH_DECISION_ENFORCE_ACCEPTS_LANE_JOBS=yes

A worker with `accepts_lane_jobs=false` must not be eligible for a lane-required job.

PATCH_DECISION_NO_LANE_DEFAULT_PATH_PASSTHROUGH=yes

A no-lane job must preserve the normal/default worker path. The lane filter must not prune the worker list for no-lane jobs. Lane-specific filtering should only apply when the job declares a lane requirement.

## Intended code patch

The next source patch should update the helper contract in `edge_controller.py` so that:

1. `_phase14j_filter_workers_for_lane(workers, job)` returns the original worker list when the persistent lane worker gate is disabled.
2. `_phase14j_filter_workers_for_lane(workers, job)` returns the original worker list for no-lane jobs, even when the gate is enabled.
3. `_phase14j_worker_eligible_for_job(worker, job)` rejects workers where `accepts_lane_jobs` is false for lane-required jobs.
4. Existing rejection behavior remains intact for wrong lane, missing capability, disabled, offline, unhealthy, stale, and primary fallback blocked cases.
5. No scheduler lane dispatch is activated.
6. No production DB rows are mutated.
7. No jobs are created or changed.
8. No service restart/reload is performed.

## Old CK smoke compatibility decision

CK_SMOKE_AFTER_PATCH_SHOULD_BE_HISTORICAL_OR_FOCUSED_ONLY=yes

Phase 14J-CK records the observed gaps at that checkpoint. After the CL/CM source patch, the CK smoke may no longer be a suitable evergreen behavior smoke because it intentionally verifies pre-patch gaps.

The next patch phase should create a new patch-specific smoke and avoid running CK as a current-behavior assertion after the helper contract changes.

## Required patch smoke behavior

The patch smoke should verify:

- DEFAULT_OFF_FILTER_PASSTHROUGH=verified
- NO_LANE_JOB_DEFAULT_PATH_PASSTHROUGH=verified
- ACCEPTS_LANE_JOBS_FALSE_REJECTED=verified
- SYNTHETIC_LANE_WORKER_ACCEPTED=verified
- PRIMARY_FALLBACK_BLOCKED_FOR_LANE_REQUIRED_JOB=verified
- WRONG_LANE_REJECTED=verified
- MISSING_CAPABILITY_REJECTED=verified
- OFFLINE_OR_UNHEALTHY_WORKER_REJECTED=verified
- DISABLED_WORKER_REJECTED=verified
- LANE_REQUIRED_WITH_NO_LANE_WORKER_FAILS_SAFE=verified
- ENVIRONMENT_RESTORED_AFTER_IN_PROCESS_TEST=verified

## Boundaries preserved

- SOURCE_MUTATION=not_performed
- DB_MUTATION=not_performed
- JOB_MUTATION=not_performed
- SERVICE_RESTART_RELOAD=not_performed
- CT101_CALL=not_performed
- MODEL_OLLAMA_CALL=not_performed
- SCHEDULER_LANE_DISPATCH_ACTIVATION=not_performed
- PRIMARY_WORKER_FILTERING_ACTIVATION=not_performed
- PERSISTENT_LANE_WORKER_STARTUP=not_performed
- ROUTER_ROLLOUT=not_performed
- WARMUP_EXECUTION=not_performed
- DO_NOT_RERUN_14J_AG_APPLY_WRAPPER=preserved
- NO_SECRETS_PRINTED=yes

## Security follow-up

SECURITY_FOLLOWUP_REQUIRED=rotate_exposed_smtp_credential

Do not print full systemd drop-in contents. Rotate the previously exposed SMTP credential in a separate guarded security-maintenance phase.

## Result

NEXT_SAFE_PHASE=source_patch_accepts_lane_jobs_and_no_lane_filter_contract
