# Phase 14J-CK - Gate B0 Synthetic Worker Availability Smoke Artifact

PHASE_14J_CK_GATE_B0_SYNTHETIC_WORKER_AVAILABILITY_SMOKE_ARTIFACT

## Scope

MUTATION_SCOPE=docs_smoke_only_record_gate_b0_observed_gaps

This phase records the Gate B0 synthetic worker availability smoke result. It uses pure in-process Python helper testing against extracted helper functions from `edge_controller.py`.

It does not enable runtime, does not mutate the production DB, does not create jobs, does not start workers, does not call CT101, and does not call model/Ollama endpoints.

## Starting checkpoint

- START_HEAD=39292a7
- START_TAG=controller-phase-14j-cj-gate-b-worker-availability-plan-2026-06-16
- SERVICE=edge-queue-controller.service
- service_active=active
- service_EDGE_PERSISTENT_LANE_WORKERS_ENABLED=<unset>
- sqlite_quick_check=ok
- worker_counts=0,0,0,0

## Gate B0 observed behavior

- HELPER_DEPENDENCY_CLOSURE_EXTRACTION=verified
- DEFAULT_OFF_FILTER_PASSTHROUGH=verified
- ENABLED_GATE_ACCEPTS_TRUTHY_VALUES=verified
- SYNTHETIC_LANE_WORKER_ACCEPTED=verified
- PRIMARY_FALLBACK_BLOCKED_FOR_LANE_REQUIRED_JOB=verified
- WRONG_LANE_REJECTED=verified
- MISSING_CAPABILITY_REJECTED=verified
- OFFLINE_OR_UNHEALTHY_WORKER_REJECTED=verified
- DISABLED_WORKER_REJECTED=verified
- LANE_REQUIRED_WITH_NO_LANE_WORKER_FAILS_SAFE=verified
- ENVIRONMENT_RESTORED_AFTER_IN_PROCESS_TEST=verified

## Gate B0 gaps discovered

ACCEPTS_LANE_JOBS_FALSE_REJECTION_GAP=observed

For a lane-required study job, the current helper returns:

```text
study-good,not-accepting
```

Expected stricter future behavior:

```text
study-good
```

NO_LANE_ENABLED_GATE_ELIGIBILITY_PRUNING=observed

For a no-lane job while the in-process gate is enabled, the helper does not preserve the full original synthetic worker list. It applies eligibility pruning and returns:

```text
primary,study-good,wrong-lane,not-accepting
```

This means the original "full list passthrough" expectation is not the current enabled-gate contract. The no-lane behavior needs a contract decision before scheduler lane dispatch.

NO_LANE_FULL_LIST_PASSTHROUGH_NOT_VERIFIED=observed

## Interpretation

Gate B0 cannot be considered fully passed for worker availability safety until:

1. The helper contract is patched to enforce `accepts_lane_jobs=false`, or the project explicitly decides that field is enforced elsewhere before dispatch.
2. The no-lane enabled-gate behavior is clarified as either:
   - expected eligibility pruning, or
   - a bug that should preserve the full worker list.

## Capacity note

CAPACITY_ENFORCEMENT_LOCATION=scheduler_scoring_or_later_runtime_gate

Capacity remains guarded by existing scheduler/worker scoring behavior and should be verified in a later bounded gate before scheduler lane dispatch.

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

## Security follow-up

SECURITY_FOLLOWUP_REQUIRED=rotate_exposed_smtp_credential

Do not print full systemd drop-in contents. Rotate the previously exposed SMTP credential in a separate guarded security-maintenance phase.

## Result

GATE_B0_RESULT=blocked_by_accepts_lane_jobs_gap_and_no_lane_contract_clarification

NEXT_SAFE_PHASE=patch_accepts_lane_jobs_filter_contract_and_clarify_no_lane_filter_contract
