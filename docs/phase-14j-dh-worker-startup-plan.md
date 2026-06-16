# Phase 14J-DH - Worker Startup Plan

PHASE_14J_DH_WORKER_STARTUP_PLAN

## Scope

MUTATION_SCOPE=docs_smoke_only_worker_startup_plan

This phase plans a later bounded persistent lane worker startup step after the seeded study lane metadata row was enabled but left offline.

No source is mutated. No production DB rows are changed. No jobs are mutated. No service is restarted or reloaded. No worker is started. No runtime is activated in this phase.

## Starting checkpoint

- START_HEAD=be14679
- START_TAG=controller-phase-14j-dg-production-lane-row-enablement-result-checkpoint-and-pre-df-smoke-compatibility-2026-06-16
- service_active=active
- service_enabled=enabled
- service_EDGE_PERSISTENT_LANE_WORKERS_ENABLED=<unset>
- sqlite_quick_check=ok
- worker_facts=2,1,1,1
- study_summary=lane,study,1,0,offline,offline
- jobs_summary=failed,1;forwarded,20;queued,1

## Carried-forward gate result

- PRODUCTION_LANE_ROW_ENABLEMENT_RESULT_CHECKPOINT=completed
- PRODUCTION_LANE_ROW_ENABLEMENT_EXECUTION_RESULT=passed_backup_first_single_row_disabled_1_to_0
- PRODUCTION_DB_MUTATION=performed_in_prior_phase_df
- UPDATED_WORKER_ID=study-lane-metadata-default-off
- UPDATED_FIELD=disabled
- UPDATED_FROM=1
- UPDATED_TO=0
- STATE_REMAINED_OFFLINE=verified
- COMPUTED_HEALTH_REMAINED_OFFLINE=verified
- SERVICE_FLAG_REMAINED_UNSET=verified
- JOB_SUMMARY_UNCHANGED=verified
- ROW_METADATA_ENABLED_BUT_RUNTIME_OFFLINE=yes
- ROW_NOT_ELIGIBLE_UNTIL_WORKER_STARTED_AND_HEALTHY=yes
- PRE_DF_SMOKE_COMPATIBILITY_UPDATED=yes

## Worker startup plan

WORKER_STARTUP_PLAN=ready_for_explicit_approval_execution

The next execution phase should be bounded and should only attempt to start/observe the persistent study lane worker path. It must not activate scheduler lane dispatch or primary-worker filtering.

The planned execution should verify:

1. Pre-start service, DB, worker, and job facts.
2. Controller lane flag status before startup.
3. Study lane metadata row remains `lane,study,1,0,offline,offline` before startup.
4. Only the approved persistent lane worker startup path is activated.
5. No CT101 call is performed unless explicitly approved later.
6. No model/Ollama endpoint call is performed.
7. No production job mutation is performed.
8. No scheduler lane dispatch activation is performed.
9. No primary-worker filtering activation is performed.
10. Post-start worker facts are captured.
11. Jobs summary remains unchanged.
12. Rollback/stop instructions are documented if the worker becomes active unexpectedly.

## Required constraints for the next execution phase

- WORKER_STARTUP_REQUIRES_EXPLICIT_APPROVAL=yes
- SCHEDULER_LANE_DISPATCH_ACTIVATION_REQUIRES_EXPLICIT_APPROVAL=yes
- PRIMARY_WORKER_FILTERING_ACTIVATION_REQUIRES_EXPLICIT_APPROVAL=yes
- CT101_OR_MODEL_CALL_REQUIRES_EXPLICIT_APPROVAL=yes
- PRODUCTION_JOB_MUTATION_ALLOWED=no
- PRODUCTION_DB_MUTATION_ALLOWED=no
- DO_NOT_RERUN_14J_AG_APPLY_WRAPPER=preserved

## Next phase

NEXT_PHASE_NAME=phase-14j-di-persistent-lane-worker-startup-execution

Required approval text:

I approve Phase 14J-DI bounded persistent lane worker startup execution for the already-enabled study lane metadata row, with no production DB mutation, no job mutation, no CT101 call, no model/Ollama endpoint call, no scheduler lane dispatch activation, no primary-worker filtering activation, no runtime activation beyond bounded persistent lane worker startup observation, and no rerun of the 14J-AG apply wrapper.

## Boundaries preserved by DH

- SOURCE_MUTATION=not_performed
- PRODUCTION_DB_MUTATION=not_performed
- JOB_MUTATION=not_performed
- SERVICE_RESTART_RELOAD=not_performed
- CT101_CALL=not_performed
- MODEL_OLLAMA_CALL=not_performed
- SCHEDULER_LANE_DISPATCH_ACTIVATION=not_performed
- PRIMARY_WORKER_FILTERING_ACTIVATION=not_performed
- PERSISTENT_LANE_WORKER_STARTUP=not_performed
- RUNTIME_ACTIVATION=not_performed
- DO_NOT_RERUN_14J_AG_APPLY_WRAPPER=preserved
- NO_SECRETS_PRINTED=yes

## Result

WORKER_STARTUP_PLAN_RESULT=ready_for_explicit_approval_execution

NEXT_SAFE_PHASE=persistent_lane_worker_startup_execution_requires_approval
