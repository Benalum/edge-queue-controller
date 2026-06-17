# Phase 14J-DM - Worker Startup Execution Contract Extension Plan

PHASE_14J_DM_WORKER_STARTUP_EXECUTION_CONTRACT_EXTENSION_PLAN

## Scope

MUTATION_SCOPE=docs_smoke_only_worker_startup_execution_contract_extension_plan

This phase plans the next contract extension after Phase 14J-DL blocked bounded worker liveness startup because no allowed non-CT101/non-model startup observation path was proven.

No source is mutated. No production DB rows are changed. No jobs are mutated. No service is restarted or reloaded. No controller power endpoint is called. No worker is started. No runtime is activated in this phase.

## Starting checkpoint

- START_HEAD=d5e092a
- START_TAG=controller-phase-14j-dl-bounded-worker-liveness-startup-execution-2026-06-16
- service_active=active
- service_enabled=enabled
- service_EDGE_PERSISTENT_LANE_WORKERS_ENABLED=<unset>
- sqlite_quick_check=ok
- worker_facts=2,1,1,1
- study_summary=lane,study,1,0,offline,offline
- jobs_summary=failed,1;forwarded,20;queued,1

## DL result carried forward

- BOUNDED_WORKER_LIVENESS_STARTUP_EXECUTION_RESULT=blocked_without_liveness_mutation
- DL_EXECUTION_GUARD_RESULT=blocked_without_liveness_mutation
- BLOCK_REASON=no_allowed_non_ct101_non_model_startup_observation_path
- SAFE_STARTUP_OBSERVATION_PATH=no
- LIVENESS_DB_MUTATION_PERFORMED=no
- PERSISTENT_LANE_WORKER_STARTUP_PERFORMED=no
- PRODUCTION_STATE_UNCHANGED_AFTER_GUARD=verified
- SERVICE_FLAG_REMAINED_UNSET=verified
- JOB_SUMMARY_UNCHANGED=verified
- WORKER_FACTS_UNCHANGED=verified
- STUDY_ROW_REMAINED_ENABLED_OFFLINE=verified
- RUNTIME_ACTIVATION_PERFORMED=no

## Existing power endpoint inventory

- POWER_START_WORKER_PLAN_ENDPOINT_PRESENT=yes
- POWER_EXECUTE_START_WORKER_ENDPOINT_PRESENT=yes
- POWER_EXECUTE_WAKE_AND_START_WORKER_ENDPOINT_PRESENT=yes

## Contract extension decision

WORKER_STARTUP_EXECUTION_CONTRACT_EXTENSION_PLAN=ready_for_explicit_approval_dry_run

Before attempting any worker start, the next safe phase should call only the local controller dry-run planning endpoint:

- planned_endpoint=/power/start-worker-plan
- planned_target_name=llms_ollama
- endpoint_mode=dry_run_only
- expected_no_worker_start=yes
- expected_no_liveness_db_mutation=yes
- expected_no_job_mutation=yes
- expected_no_service_restart_reload=yes
- expected_no_ct101_call=yes
- expected_no_model_ollama_call=yes
- expected_no_scheduler_lane_dispatch_activation=yes
- expected_no_primary_worker_filtering_activation=yes

The dry-run result should decide whether a later execution may call the guarded start endpoint. The actual start endpoint must still require separate explicit approval.

## Next phase

NEXT_PHASE_NAME=phase-14j-dn-controller-power-start-worker-dry-run

Required approval text:

I approve Phase 14J-DN controller power start-worker dry-run only for target llms_ollama, with no worker start, no production DB mutation, no production job mutation, no service restart/reload, no CT101 call, no model/Ollama endpoint call, no scheduler lane dispatch activation, no primary-worker filtering activation, no runtime activation, and no rerun of the 14J-AG apply wrapper.

## Boundaries preserved by DM

- SOURCE_MUTATION=not_performed
- PRODUCTION_DB_MUTATION=not_performed
- JOB_MUTATION=not_performed
- SERVICE_RESTART_RELOAD=not_performed
- CT101_CALL=not_performed
- MODEL_OLLAMA_CALL=not_performed
- POWER_ENDPOINT_CALL=not_performed
- SCHEDULER_LANE_DISPATCH_ACTIVATION=not_performed
- PRIMARY_WORKER_FILTERING_ACTIVATION=not_performed
- PERSISTENT_LANE_WORKER_STARTUP=not_performed
- RUNTIME_ACTIVATION=not_performed
- DO_NOT_RERUN_14J_AG_APPLY_WRAPPER=preserved
- NO_SECRETS_PRINTED=yes

## Result

WORKER_STARTUP_EXECUTION_CONTRACT_EXTENSION_PLAN_RESULT=ready_for_explicit_approval_dry_run

NEXT_SAFE_PHASE=controller_power_start_worker_dry_run_requires_approval
