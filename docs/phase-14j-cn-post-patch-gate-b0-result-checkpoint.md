# Phase 14J-CN - Post-Patch Gate B0 Result Checkpoint

PHASE_14J_CN_POST_PATCH_GATE_B0_RESULT_CHECKPOINT

## Scope

MUTATION_SCOPE=docs_smoke_only_post_patch_checkpoint_and_historical_smoke_compatibility

This phase records the post-CM Gate B0 result checkpoint and converts the older CK smoke into a historical marker-only compatibility smoke.

No runtime is activated. No service is restarted. No DB rows or jobs are mutated.

## Starting checkpoint

- START_HEAD=f9bc18d
- START_TAG=controller-phase-14j-cm-source-patch-accepts-lane-jobs-and-no-lane-filter-contract-2026-06-16
- SERVICE=edge-queue-controller.service
- service_active=active
- service_EDGE_PERSISTENT_LANE_WORKERS_ENABLED=<unset>
- sqlite_quick_check=ok
- worker_counts=0,0,0,0

## CM result carried forward

- GATE_B0_PATCH_RESULT=accepts_lane_jobs_and_no_lane_filter_contract_patched
- PATCHED_ACCEPTS_LANE_JOBS_ENFORCEMENT=yes
- PATCHED_NO_LANE_FILTER_PASSTHROUGH=yes
- DEFAULT_OFF_FILTER_PASSTHROUGH=verified
- ACCEPTS_LANE_JOBS_FALSE_REJECTED=verified
- NO_LANE_JOB_DEFAULT_PATH_PASSTHROUGH=verified
- SYNTHETIC_LANE_WORKER_ACCEPTED=verified
- LANE_REQUIRED_WITH_NO_LANE_WORKER_FAILS_SAFE=verified

## CK compatibility decision

CK_HISTORICAL_GAP_SMOKE_MARKER_ONLY_AFTER_CM=yes

Phase 14J-CK intentionally documents the pre-patch gap. After CM, the helper behavior is patched, so CK must not keep executing pre-patch behavior assertions as evergreen checks.

## Boundaries preserved

- EDGE_CONTROLLER_MUTATION=not_performed_by_cn
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

POST_PATCH_GATE_B0_RESULT=patched_and_checkpointed

NEXT_SAFE_PHASE=gate_b1_worker_availability_metadata_plan_or_rotate_exposed_smtp_credential
