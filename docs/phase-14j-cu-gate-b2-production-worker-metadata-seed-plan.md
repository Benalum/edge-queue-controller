# Phase 14J-CU - Gate B2 Production Worker Metadata Seed Plan

PHASE_14J_CU_GATE_B2_PRODUCTION_WORKER_METADATA_SEED_PLAN

## Scope

MUTATION_SCOPE=docs_smoke_only_gate_b2_production_worker_metadata_seed_plan

This phase plans the next bounded production worker metadata seed step.

No source is mutated. No production DB rows are changed in this phase. No runtime is activated.

## Starting checkpoint

- START_HEAD=707dfeb
- START_TAG=controller-phase-14j-ct-gate-b1-temp-db-worker-availability-result-checkpoint-2026-06-16
- SERVICE=edge-queue-controller.service
- service_active=active
- service_enabled=enabled
- service_EDGE_PERSISTENT_LANE_WORKERS_ENABLED=<unset>
- sqlite_quick_check=ok
- worker_facts=0,0,0,0
- jobs_summary=failed,1;forwarded,20;queued,1

## Carried-forward Gate B1 result

- GATE_B1_RESULT=passed_temp_db_worker_availability_metadata
- GATE_B1_TEMP_DB_WORKER_AVAILABILITY_SMOKE_RESULT=passed
- PRODUCTION_DB_UNCHANGED_AFTER_TEMP_DB_SMOKE=verified
- DEFAULT_OFF_FILTER_PASSTHROUGH_WITH_TEMP_DB=verified
- TEMP_DB_LANE_REQUIRED_ACCEPTS_ONLY_ELIGIBLE_STUDY_WORKER=verified
- TEMP_DB_ACCEPTS_LANE_JOBS_FALSE_REJECTED=verified
- TEMP_DB_NO_LANE_JOB_DEFAULT_PATH_PASSTHROUGH=verified
- TEMP_DB_LANE_REQUIRED_WITH_NO_ELIGIBLE_WORKER_FAILS_SAFE=verified

## Gate B2 plan

GATE_B2_PLAN=guarded_backup_first_default_off_production_worker_metadata_seed

The next safe phase should seed one or more production worker metadata rows only after creating a timestamped SQLite backup.

The production seed must remain default-off and non-activating:

- EDGE_PERSISTENT_LANE_WORKERS_ENABLED must remain unset.
- No worker process may be started.
- No scheduler lane dispatch may be activated.
- No primary-worker filtering activation may occur.
- No jobs may be mutated.
- No CT101/model/Ollama calls may occur.
- The seed must be rollback-safe.
- The seed must not rerun the 14J-AG schema apply wrapper.

## Planned seed shape

The next phase should insert or upsert only metadata rows in the `workers` table.

Minimum planned rows:

- PRIMARY_METADATA_ROW=primary_default_worker_metadata
- STUDY_LANE_METADATA_ROW=study_lane_worker_metadata_default_off

The planned study-lane metadata row should be safe while default-off:

- worker_role=lane
- worker_lane=study
- accepts_lane_jobs=1
- disabled=1 or state=offline unless explicitly proven safe
- current_running_jobs=0
- max_concurrent_jobs bounded
- capabilities include ollama_chat and study if schema supports persisted capabilities
- no worker process startup

## Required backup and rollback

- BACKUP_REQUIRED_BEFORE_PRODUCTION_DB_MUTATION=yes
- ROLLBACK_PLAN_REQUIRED=yes
- ROLLBACK_SHOULD_RESTORE_BACKUP_OR_DELETE_ONLY_SEEDED_ROWS=yes
- POST_SEED_QUICK_CHECK_REQUIRED=yes
- POST_SEED_DEFAULT_OFF_GUARD_REQUIRED=yes
- POST_SEED_JOB_SUMMARY_UNCHANGED_REQUIRED=yes

## Next phase requirements

NEXT_PHASE_NAME=phase-14j-cv-gate-b2-guarded-production-worker-metadata-seed

The next phase may mutate production DB only if it:

1. Confirms the exact CT checkpoint.
2. Confirms service is active/enabled.
3. Confirms EDGE_PERSISTENT_LANE_WORKERS_ENABLED is unset.
4. Confirms PRAGMA quick_check is ok.
5. Captures pre-seed worker facts and job summary.
6. Creates a timestamped SQLite backup before mutation.
7. Inserts or upserts bounded worker metadata rows only.
8. Runs a focused smoke that verifies seeded metadata and default-off behavior.
9. Verifies jobs summary unchanged.
10. Verifies no runtime activation occurred.
11. Commits docs/smoke evidence only, not the DB file.

## Boundaries preserved by CU

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

GATE_B2_PRODUCTION_WORKER_METADATA_SEED_PLAN_RESULT=ready_for_guarded_backup_first_seed

NEXT_SAFE_PHASE=gate_b2_guarded_production_worker_metadata_seed
