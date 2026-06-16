# Phase 14J-CM - Source Patch accepts_lane_jobs and No-Lane Filter Contract

PHASE_14J_CM_SOURCE_PATCH_ACCEPTS_LANE_JOBS_AND_NO_LANE_FILTER_CONTRACT

## Scope

MUTATION_SCOPE=source_docs_smoke_only_lane_filter_contract_patch

This phase patches the lane helper contract in `edge_controller.py`.

## Patch behavior

- ACCEPTS_LANE_JOBS_FALSE_REJECTED=verified
- NO_LANE_JOB_DEFAULT_PATH_PASSTHROUGH=verified
- DEFAULT_OFF_FILTER_PASSTHROUGH=verified
- SYNTHETIC_LANE_WORKER_ACCEPTED=verified
- PRIMARY_FALLBACK_BLOCKED_FOR_LANE_REQUIRED_JOB=verified
- WRONG_LANE_REJECTED=verified
- MISSING_CAPABILITY_REJECTED=verified
- OFFLINE_OR_UNHEALTHY_WORKER_REJECTED=verified
- DISABLED_WORKER_REJECTED=verified
- LANE_REQUIRED_WITH_NO_LANE_WORKER_FAILS_SAFE=verified
- ENVIRONMENT_RESTORED_AFTER_IN_PROCESS_TEST=verified

## Source changes

- PATCHED_EDGE_CONTROLLER=yes
- PATCHED_ACCEPTS_LANE_JOBS_ENFORCEMENT=yes
- PATCHED_NO_LANE_FILTER_PASSTHROUGH=yes

The helper now rejects workers with `accepts_lane_jobs=false` for lane-required jobs.

The lane filter now returns the original worker list for no-lane jobs, even when the lane-worker gate is enabled.

## Starting checkpoint

- START_HEAD=8452b72
- START_TAG=controller-phase-14j-cl-accepts-lane-jobs-and-no-lane-filter-contract-patch-plan-2026-06-16
- SERVICE=edge-queue-controller.service
- service_active=active
- service_EDGE_PERSISTENT_LANE_WORKERS_ENABLED=<unset>
- sqlite_quick_check=ok
- worker_counts=0,0,0,0

## Boundaries preserved

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

## Compatibility note

CK_HISTORICAL_GAP_SMOKE_NOT_RERUN_AS_CURRENT_BEHAVIOR=yes

Phase 14J-CK intentionally records the pre-patch observed gaps. CM uses a new patch-specific smoke for current behavior.

## Security follow-up

SECURITY_FOLLOWUP_REQUIRED=rotate_exposed_smtp_credential

Do not print full systemd drop-in contents. Rotate the previously exposed SMTP credential in a separate guarded security-maintenance phase.

## Result

GATE_B0_PATCH_RESULT=accepts_lane_jobs_and_no_lane_filter_contract_patched

NEXT_SAFE_PHASE=post_patch_gate_b0_result_checkpoint
