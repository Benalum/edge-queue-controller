# Phase 14J-DN - Controller Power Start-Worker Dry-Run

PHASE_14J_DN_CONTROLLER_POWER_START_WORKER_DRY_RUN

## Scope

MUTATION_SCOPE=controller_power_start_worker_dry_run_only

This phase called only the local controller dry-run planning endpoint for target `llms_ollama`.

No worker was started. No production DB rows were changed. No production jobs were mutated. No service was restarted or reloaded. No CT101 call, model/Ollama endpoint call, scheduler lane dispatch activation, primary-worker filtering activation, runtime activation, or 14J-AG apply wrapper rerun occurred.

## Approval

APPROVAL_CONFIRMED=yes

## Starting checkpoint

- START_HEAD=ba06a34
- START_TAG=controller-phase-14j-dm-worker-startup-execution-contract-extension-plan-2026-06-16
- service_active_before=active
- service_enabled_before=enabled
- service_EDGE_PERSISTENT_LANE_WORKERS_ENABLED_before=<unset>
- sqlite_quick_check_before=ok
- worker_facts_before=2,1,1,1
- study_summary_before=lane,study,1,0,offline,offline
- jobs_summary_before=failed,1;forwarded,20;queued,1

## Dry-run endpoint call

- POWER_ENDPOINT_CALL=performed_dry_run_only
- PLANNED_ENDPOINT=/power/start-worker-plan
- TARGET_NAME=llms_ollama
- CONTROLLER_URL=local_controller_127_0_0_1_7070
- CURL_EXIT=0
- DRY_RUN_HTTP_STATUS=504
- DRY_RUN_RESPONSE_JSON=yes
- DRY_RUN_RESPONSE_TOP_KEYS=detail
- DRY_RUN_RESPONSE_HAS_DRY_RUN_NOTE=no
- DRY_RUN_RESPONSE_ELIGIBLE_VALUE=unknown
- DRY_RUN_RESPONSE_BLOCKED_REASON=none
- DRY_RUN_RESPONSE_NOTE_SUMMARY=none
- DRY_RUN_CALL_RESULT=completed_http_non_2xx

## Guard result

- WORKER_START_PERFORMED=no
- LIVENESS_DB_MUTATION_PERFORMED=no
- PRODUCTION_DB_MUTATION=not_performed
- JOB_MUTATION=not_performed
- SERVICE_RESTART_RELOAD=not_performed
- CT101_CALL=not_performed
- MODEL_OLLAMA_CALL=not_performed
- SCHEDULER_LANE_DISPATCH_ACTIVATION=not_performed
- PRIMARY_WORKER_FILTERING_ACTIVATION=not_performed
- RUNTIME_ACTIVATION=not_performed
- DO_NOT_RERUN_14J_AG_APPLY_WRAPPER=preserved
- NO_SECRETS_PRINTED=yes

## Current post-call state

- service_active_after=active
- service_enabled_after=enabled
- service_EDGE_PERSISTENT_LANE_WORKERS_ENABLED_after=<unset>
- sqlite_quick_check_after=ok
- worker_facts_after=2,1,1,1
- study_summary_after=lane,study,1,0,offline,offline
- jobs_summary_after=failed,1;forwarded,20;queued,1

## Verification

- PRODUCTION_STATE_UNCHANGED_AFTER_DRY_RUN=verified
- SERVICE_FLAG_REMAINED_UNSET=verified
- JOB_SUMMARY_UNCHANGED=verified
- WORKER_FACTS_UNCHANGED=verified
- STUDY_ROW_REMAINED_ENABLED_OFFLINE=verified

## Next phase

NEXT_PHASE_NAME=phase-14j-do-controller-power-start-worker-dry-run-result-checkpoint

The next phase should record the dry-run result and decide whether the guarded start endpoint can be considered in a later explicit-approval phase.

## Result

CONTROLLER_POWER_START_WORKER_DRY_RUN_RESULT=completed_http_non_2xx

NEXT_SAFE_PHASE=controller_power_start_worker_dry_run_result_checkpoint
