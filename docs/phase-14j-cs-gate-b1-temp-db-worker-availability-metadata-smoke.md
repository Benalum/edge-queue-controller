# Phase 14J-CS - Gate B1 Temp-DB Worker Availability Metadata Smoke

PHASE_14J_CS_GATE_B1_TEMP_DB_WORKER_AVAILABILITY_METADATA_SMOKE

## Scope

MUTATION_SCOPE=docs_smoke_repair2_temp_db_only_worker_availability_metadata_smoke

This phase adds and runs a temp-DB-only worker availability metadata smoke.

No source is mutated. No production DB rows are changed. No runtime is activated. The smoke copies the production SQLite database to a temporary path, inserts synthetic worker rows only into the temp copy, tests the patched lane worker helper behavior using persisted worker-style rows, then verifies the production database remains unchanged.

## Repair notes

- INITIAL_CS_ATTEMPT_RESULT=blocked_by_helper_dependency_name_drift
- FIRST_CS_REPAIR_RESULT=blocked_by_temp_db_unhealthy_worker_fixture_mapping
- REPAIR_STRATEGY=ast_recursive_helper_dependency_extraction
- REPAIR2_STRATEGY=defensive_persisted_health_state_fixture_mapping

The repaired smoke extracts helper dependencies recursively and maps unhealthy/offline values into persisted worker fields defensively, including state/status/health/computed_health style columns when present.

## Starting checkpoint

- START_HEAD=2d13465
- START_TAG=controller-phase-14j-cr-gate-b1-worker-availability-metadata-plan-2026-06-16
- SERVICE=edge-queue-controller.service
- service_active=active
- service_enabled=enabled
- service_EDGE_PERSISTENT_LANE_WORKERS_ENABLED=<unset>
- sqlite_quick_check=ok
- worker_facts_before=0,0,0,0

## Results expected and verified

- TEMP_DB_CREATED=verified
- TEMP_DB_WORKER_ROWS_INSERTED=verified
- TEMP_DB_ONLY_INSERTS=verified
- DEFAULT_OFF_FILTER_PASSTHROUGH_WITH_TEMP_DB=verified
- TEMP_DB_LANE_REQUIRED_ACCEPTS_ONLY_ELIGIBLE_STUDY_WORKER=verified
- TEMP_DB_ACCEPTS_LANE_JOBS_FALSE_REJECTED=verified
- TEMP_DB_NO_LANE_JOB_DEFAULT_PATH_PASSTHROUGH=verified
- TEMP_DB_PRIMARY_FALLBACK_BLOCKED_FOR_LANE_REQUIRED_JOB=verified
- TEMP_DB_WRONG_LANE_REJECTED=verified
- TEMP_DB_MISSING_CAPABILITY_REJECTED=verified
- TEMP_DB_OFFLINE_OR_UNHEALTHY_WORKER_REJECTED=verified
- TEMP_DB_DISABLED_WORKER_REJECTED=verified
- TEMP_DB_CAPACITY_SATURATED_WORKER_REJECTED=verified
- TEMP_DB_LANE_REQUIRED_WITH_NO_ELIGIBLE_WORKER_FAILS_SAFE=verified
- PRODUCTION_DB_UNCHANGED_AFTER_TEMP_DB_SMOKE=verified
- ENVIRONMENT_RESTORED_AFTER_IN_PROCESS_TEST=verified

## Boundaries preserved by CS

- SOURCE_MUTATION=not_performed
- PRODUCTION_DB_MUTATION=not_performed
- TEMP_DB_MUTATION=performed
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

GATE_B1_TEMP_DB_WORKER_AVAILABILITY_SMOKE_RESULT=passed

NEXT_SAFE_PHASE=gate_b1_temp_db_worker_availability_result_checkpoint
