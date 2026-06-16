# Phase 14J-DB - Bounded Service Flag Activation With Disabled/Offline Seeded Rows Plan

PHASE_14J_DB_BOUNDED_SERVICE_FLAG_ACTIVATION_WITH_DISABLED_OFFLINE_SEEDED_ROWS_PLAN

## Scope

MUTATION_SCOPE=docs_smoke_only_bounded_service_flag_activation_with_disabled_offline_seeded_rows_plan

This phase plans a later bounded controller service flag activation and rollback check.

No source is mutated. No production DB rows are changed. No jobs are mutated. No service is restarted or reloaded in this phase. No runtime is activated.

## Starting checkpoint

- START_HEAD=9100d48
- START_TAG=controller-phase-14j-da-lane-activation-stage-plan-2026-06-16
- service_active=active
- service_enabled=enabled
- service_EDGE_PERSISTENT_LANE_WORKERS_ENABLED=<unset>
- sqlite_quick_check=ok
- worker_facts=2,1,1,1
- seeded_count=2
- safe_seeded_count=2
- study_summary=lane,study,1,1,offline,offline
- jobs_summary=failed,1;forwarded,20;queued,1

## Carried-forward readiness

- LANE_ACTIVATION_STAGE_PLAN_RESULT=ready_for_bounded_service_flag_activation_plan
- GATE_B3_SEEDED_METADATA_DEFAULT_OFF_READINESS_RESULT_CHECKPOINT=completed
- GATE_B3_SEEDED_METADATA_DEFAULT_OFF_READINESS_SMOKE_RESULT=passed
- SEEDED_WORKER_ROWS_PRESENT=verified
- STUDY_LANE_METADATA_SHAPE=verified
- SEEDED_ROWS_DISABLED_OR_OFFLINE=verified
- DEFAULT_OFF_ENV_REMAINED_UNSET=verified
- DEFAULT_OFF_FILTER_PASSTHROUGH_WITH_SEEDED_METADATA=verified
- IN_PROCESS_GATE_OVERRIDE_DISABLED_OFFLINE_SEEDED_LANE_NOT_ELIGIBLE=verified
- PRODUCTION_DB_UNCHANGED_AFTER_READINESS_SMOKE=verified
- JOB_SUMMARY_UNCHANGED=verified

## Planned bounded service flag check

BOUNDED_SERVICE_FLAG_ACTIVATION_PLAN=ready_for_explicit_approval_execution

The next execution phase should temporarily set the controller service environment flag:

- EDGE_PERSISTENT_LANE_WORKERS_ENABLED=1

The check must be bounded and rollback-first:

1. Capture pre-activation service, DB, workers, and jobs facts.
2. Add a temporary systemd drop-in for EDGE_PERSISTENT_LANE_WORKERS_ENABLED=1.
3. Run daemon-reload and restart only the controller service.
4. Verify the service is active/enabled.
5. Verify the flag is visible.
6. Verify DB quick_check remains ok.
7. Verify jobs summary is unchanged.
8. Verify seeded worker metadata remains disabled/offline.
9. Verify disabled/offline seeded lane row does not become eligible when the flag is on.
10. Remove the temporary drop-in.
11. Run daemon-reload and restart only the controller service.
12. Verify the flag is unset again.
13. Verify service, DB, worker facts, and jobs summary remain safe.

## Explicit approval required before execution

NEXT_PHASE_NAME=phase-14j-dc-bounded-service-flag-activation-with-disabled-offline-seeded-rows-execution

The next phase requires explicit approval because it restarts the controller service and temporarily activates the service flag.

Required approval text:

I approve Phase 14J-DC bounded controller service flag activation and rollback with disabled/offline seeded rows, no production DB mutation, no job mutation, no CT101 call, no model/Ollama endpoint call, no scheduler lane dispatch activation, no primary-worker filtering activation, no persistent lane worker startup, no runtime activation beyond temporary controller flag observation, and no rerun of the 14J-AG apply wrapper.

## Boundaries preserved by DB plan

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

BOUNDED_SERVICE_FLAG_ACTIVATION_PLAN_RESULT=ready_for_explicit_approval_execution

NEXT_SAFE_PHASE=bounded_service_flag_activation_with_disabled_offline_seeded_rows_execution_requires_approval
