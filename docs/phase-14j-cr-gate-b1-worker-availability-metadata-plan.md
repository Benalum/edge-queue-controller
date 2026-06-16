# Phase 14J-CR - Gate B1 Worker Availability Metadata Plan

PHASE_14J_CR_GATE_B1_WORKER_AVAILABILITY_METADATA_PLAN

## Scope

MUTATION_SCOPE=docs_smoke_only_gate_b1_worker_availability_metadata_plan

This phase defines the next safe Gate B1 worker-availability metadata step after:

- Gate B0 helper behavior was patched in CM.
- CK was converted to historical gap compatibility in CN.
- SMTP credential rotation and old-key revocation were closed in CP/CQ.

No source is mutated. No production DB rows are changed. No runtime is activated.

## Starting checkpoint

- START_HEAD=8bbfaa3
- START_TAG=controller-phase-14j-cq-old-resend-smtp-api-key-revocation-checkpoint-2026-06-16
- SERVICE=edge-queue-controller.service
- service_active=active
- service_enabled=enabled
- service_EDGE_PERSISTENT_LANE_WORKERS_ENABLED=<unset>
- sqlite_quick_check=ok
- worker_facts=0,0,0,0

## Carried-forward security result

- SECURITY_FOLLOWUP_RESULT=smtp_credential_rotated_and_old_key_revoked
- SMTP_ROTATION_RESULT=rotated_loaded_and_provider_verified
- RESEND_OLD_API_KEY_DELETED=reported_by_user
- NO_SECRETS_PRINTED=yes

## Carried-forward lane filter result

- GATE_B0_PATCH_RESULT=accepts_lane_jobs_and_no_lane_filter_contract_patched
- PATCHED_ACCEPTS_LANE_JOBS_ENFORCEMENT=yes
- PATCHED_NO_LANE_FILTER_PASSTHROUGH=yes
- ACCEPTS_LANE_JOBS_FALSE_REJECTED=verified
- NO_LANE_JOB_DEFAULT_PATH_PASSTHROUGH=verified
- LANE_REQUIRED_WITH_NO_LANE_WORKER_FAILS_SAFE=verified

## Gate B1 plan

GATE_B1_PLAN=temp_db_worker_availability_metadata_smoke

The next safe phase should use a temporary SQLite DB copy, not the production DB, to verify worker availability metadata behavior across realistic persisted worker rows.

Planned next phase:

- NEXT_PHASE_NAME=phase-14j-cs-gate-b1-temp-db-worker-availability-metadata-smoke
- TEMP_DB_ONLY=yes
- PRODUCTION_DB_MUTATION=not_performed
- SERVICE_RESTART_RELOAD=not_performed
- RUNTIME_ACTIVATION=not_performed

The temp-DB smoke should:

1. Copy `edge_queue.sqlite3` to a temporary path under `/tmp`.
2. Insert synthetic workers only into the temp DB.
3. Include at least one accepting study-lane worker.
4. Include at least one non-accepting lane worker.
5. Include primary fallback, wrong-lane, missing-capability, disabled, offline, and capacity-saturated examples.
6. Verify the patched helper accepts only eligible lane workers for lane-required jobs.
7. Verify no-lane/default-path jobs still pass through the full worker list.
8. Verify the production DB remains unchanged after the temp test.
9. Verify `EDGE_PERSISTENT_LANE_WORKERS_ENABLED` remains unset.
10. Avoid CT101, model/Ollama, scheduler, worker startup, and job mutations.

## Boundaries preserved by CR

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

GATE_B1_METADATA_PLAN_RESULT=ready_for_temp_db_worker_availability_smoke

NEXT_SAFE_PHASE=gate_b1_temp_db_worker_availability_metadata_smoke
