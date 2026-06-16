#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-da-lane-activation-stage-plan"
DOC="docs/${PHASE}.md"
DB="edge_queue.sqlite3"
SERVICE="edge-queue-controller.service"

echo "=== Phase 14J-DA smoke: lane activation stage plan ==="

test -f "$DOC"
echo "PASS: DA doc exists"

for marker in \
  "PHASE_14J_DA_LANE_ACTIVATION_STAGE_PLAN" \
  "MUTATION_SCOPE=docs_smoke_only_lane_activation_stage_plan" \
  "GATE_B3_SEEDED_METADATA_DEFAULT_OFF_READINESS_RESULT_CHECKPOINT=completed" \
  "GATE_B3_SEEDED_METADATA_DEFAULT_OFF_READINESS_SMOKE_RESULT=passed" \
  "GATE_B3_SEEDED_METADATA_READINESS_RESULT=passed_default_off_non_runtime" \
  "SEEDED_WORKER_ROWS_PRESENT=verified" \
  "STUDY_LANE_METADATA_SHAPE=verified" \
  "SEEDED_ROWS_DISABLED_OR_OFFLINE=verified" \
  "DEFAULT_OFF_ENV_REMAINED_UNSET=verified" \
  "DEFAULT_OFF_FILTER_PASSTHROUGH_WITH_SEEDED_METADATA=verified" \
  "IN_PROCESS_GATE_OVERRIDE_DISABLED_OFFLINE_SEEDED_LANE_NOT_ELIGIBLE=verified" \
  "PRODUCTION_DB_UNCHANGED_AFTER_READINESS_SMOKE=verified" \
  "JOB_SUMMARY_UNCHANGED=verified" \
  "LANE_ACTIVATION_STAGE_PLAN=approved_for_planning_only" \
  "STAGE_DB_CONTROLLER_FLAG_ROLLBACK=bounded_service_flag_activation_with_disabled_offline_seeded_rows" \
  "STAGE_DB_DISABLED_OFFLINE_GATE_OBSERVATION=verify_flag_on_does_not_make_disabled_offline_seeded_lane_eligible" \
  "STAGE_DB_ROLLBACK=remove_service_flag_and_verify_default_off" \
  "NEXT_PHASE_NAME=phase-14j-db-bounded-service-flag-activation-with-disabled-offline-seeded-rows-plan" \
  "SERVICE_FLAG_ACTIVATION_REQUIRES_EXPLICIT_APPROVAL=yes" \
  "PRODUCTION_DB_ENABLEMENT_REQUIRES_EXPLICIT_APPROVAL=yes" \
  "WORKER_STARTUP_REQUIRES_EXPLICIT_APPROVAL=yes" \
  "SCHEDULER_LANE_DISPATCH_ACTIVATION_REQUIRES_EXPLICIT_APPROVAL=yes" \
  "PRIMARY_WORKER_FILTERING_ACTIVATION_REQUIRES_EXPLICIT_APPROVAL=yes" \
  "CT101_OR_MODEL_CALL_REQUIRES_EXPLICIT_APPROVAL=yes" \
  "SOURCE_MUTATION=not_performed" \
  "PRODUCTION_DB_MUTATION=not_performed" \
  "JOB_MUTATION=not_performed" \
  "SERVICE_RESTART_RELOAD=not_performed" \
  "CT101_CALL=not_performed" \
  "MODEL_OLLAMA_CALL=not_performed" \
  "SCHEDULER_LANE_DISPATCH_ACTIVATION=not_performed" \
  "PRIMARY_WORKER_FILTERING_ACTIVATION=not_performed" \
  "PERSISTENT_LANE_WORKER_STARTUP=not_performed" \
  "RUNTIME_ACTIVATION=not_performed" \
  "DO_NOT_RERUN_14J_AG_APPLY_WRAPPER=preserved" \
  "NO_SECRETS_PRINTED=yes" \
  "LANE_ACTIVATION_STAGE_PLAN_RESULT=ready_for_bounded_service_flag_activation_plan" \
  "NEXT_SAFE_PHASE=bounded_service_flag_activation_with_disabled_offline_seeded_rows_plan"; do
  grep -F "$marker" "$DOC" >/dev/null
  echo "PASS: marker found: $marker"
done

echo
echo "=== runtime/default-off seeded metadata guard, read-only ==="
service_active="$(systemctl is-active "$SERVICE" 2>/dev/null || true)"
service_enabled="$(systemctl is-enabled "$SERVICE" 2>/dev/null || true)"
service_flag="$(systemctl show "$SERVICE" -p Environment --value 2>/dev/null | tr ' ' '\n' | grep '^EDGE_PERSISTENT_LANE_WORKERS_ENABLED=' || true)"
quick_check="$(sqlite3 "file:${PWD}/${DB}?mode=ro" "PRAGMA quick_check;")"
worker_facts="$(sqlite3 -csv "file:${PWD}/${DB}?mode=ro" "
SELECT
  COUNT(*),
  COALESCE(SUM(CASE WHEN COALESCE(accepts_lane_jobs,0) NOT IN (0,'0','false','False','') THEN 1 ELSE 0 END),0),
  COALESCE(SUM(CASE WHEN COALESCE(worker_lane,'') NOT IN ('','primary') THEN 1 ELSE 0 END),0),
  COALESCE(SUM(CASE WHEN COALESCE(worker_role,'primary') <> 'primary' THEN 1 ELSE 0 END),0)
FROM workers;
")"
seeded_count="$(sqlite3 "file:${PWD}/${DB}?mode=ro" "SELECT COUNT(*) FROM workers WHERE worker_id IN ('primary-default-metadata','study-lane-metadata-default-off');")"
safe_seeded_count="$(sqlite3 "file:${PWD}/${DB}?mode=ro" "
SELECT COUNT(*)
FROM workers
WHERE worker_id IN ('primary-default-metadata','study-lane-metadata-default-off')
  AND (
    COALESCE(disabled,0) NOT IN (0,'0','false','False','')
    OR LOWER(COALESCE(state,'')) IN ('offline','disabled','unhealthy')
    OR LOWER(COALESCE(computed_health,'')) IN ('offline','disabled','unhealthy')
  );
")"
study_summary="$(sqlite3 -csv "file:${PWD}/${DB}?mode=ro" "
SELECT worker_role, worker_lane, accepts_lane_jobs, disabled, state, computed_health
FROM workers
WHERE worker_id='study-lane-metadata-default-off';
")"

echo "service_active=${service_active}"
echo "service_enabled=${service_enabled}"
echo "service_EDGE_PERSISTENT_LANE_WORKERS_ENABLED=${service_flag:-<unset>}"
echo "sqlite_quick_check=${quick_check}"
echo "worker_facts=${worker_facts}"
echo "seeded_count=${seeded_count}"
echo "safe_seeded_count=${safe_seeded_count}"
echo "study_summary=${study_summary}"

test "$service_active" = "active"
test "$service_enabled" = "enabled"
test -z "$service_flag"
test "$quick_check" = "ok"
test "$worker_facts" = "2,1,1,1"
test "$seeded_count" = "2"
test "$safe_seeded_count" = "2"
test "$study_summary" = "lane,study,1,1,offline,offline"

echo "PASS: production runtime remains default-off after DA"
echo "PASS: Phase 14J-DA lane activation stage plan smoke passed"
