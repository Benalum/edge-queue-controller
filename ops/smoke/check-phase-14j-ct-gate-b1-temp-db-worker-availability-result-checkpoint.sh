#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-ct-gate-b1-temp-db-worker-availability-result-checkpoint"
DOC="docs/${PHASE}.md"
DB="edge_queue.sqlite3"
SERVICE="edge-queue-controller.service"

echo "=== Phase 14J-CT smoke: Gate B1 temp-DB worker availability result checkpoint ==="

test -f "$DOC"
echo "PASS: CT doc exists"

for marker in \
  "PHASE_14J_CT_GATE_B1_TEMP_DB_WORKER_AVAILABILITY_RESULT_CHECKPOINT" \
  "MUTATION_SCOPE=docs_smoke_only_gate_b1_temp_db_result_checkpoint" \
  "GATE_B1_TEMP_DB_WORKER_AVAILABILITY_SMOKE_RESULT=passed" \
  "TEMP_DB_CREATED=verified" \
  "TEMP_DB_WORKER_ROWS_INSERTED=verified" \
  "TEMP_DB_ONLY_INSERTS=verified" \
  "DEFAULT_OFF_FILTER_PASSTHROUGH_WITH_TEMP_DB=verified" \
  "TEMP_DB_LANE_REQUIRED_ACCEPTS_ONLY_ELIGIBLE_STUDY_WORKER=verified" \
  "TEMP_DB_ACCEPTS_LANE_JOBS_FALSE_REJECTED=verified" \
  "TEMP_DB_NO_LANE_JOB_DEFAULT_PATH_PASSTHROUGH=verified" \
  "TEMP_DB_PRIMARY_FALLBACK_BLOCKED_FOR_LANE_REQUIRED_JOB=verified" \
  "TEMP_DB_WRONG_LANE_REJECTED=verified" \
  "TEMP_DB_MISSING_CAPABILITY_REJECTED=verified" \
  "TEMP_DB_OFFLINE_OR_UNHEALTHY_WORKER_REJECTED=verified" \
  "TEMP_DB_DISABLED_WORKER_REJECTED=verified" \
  "TEMP_DB_CAPACITY_SATURATED_WORKER_REJECTED=verified" \
  "TEMP_DB_LANE_REQUIRED_WITH_NO_ELIGIBLE_WORKER_FAILS_SAFE=verified" \
  "PRODUCTION_DB_UNCHANGED_AFTER_TEMP_DB_SMOKE=verified" \
  "ENVIRONMENT_RESTORED_AFTER_IN_PROCESS_TEST=verified" \
  "INITIAL_CS_ATTEMPT_RESULT=blocked_by_helper_dependency_name_drift" \
  "FIRST_CS_REPAIR_RESULT=blocked_by_temp_db_unhealthy_worker_fixture_mapping" \
  "REPAIR_STRATEGY=ast_recursive_helper_dependency_extraction" \
  "REPAIR2_STRATEGY=defensive_persisted_health_state_fixture_mapping" \
  "SECURITY_FOLLOWUP_RESULT=smtp_credential_rotated_and_old_key_revoked" \
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
  "GATE_B1_RESULT=passed_temp_db_worker_availability_metadata" \
  "NEXT_SAFE_PHASE=gate_b2_production_worker_metadata_seed_plan"; do
  grep -F "$marker" "$DOC" >/dev/null
  echo "PASS: marker found: $marker"
done

echo
echo "=== runtime/default-off guard, read-only ==="
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

echo "service_active=${service_active}"
echo "service_enabled=${service_enabled}"
echo "service_EDGE_PERSISTENT_LANE_WORKERS_ENABLED=${service_flag:-<unset>}"
echo "sqlite_quick_check=${quick_check}"
echo "worker_facts=${worker_facts}"

IFS=',' read -r worker_count lane_enabled non_default_lane non_primary_role <<< "$worker_facts"

test "$service_active" = "active"
test "$service_enabled" = "enabled"
test -z "$service_flag"
test "$quick_check" = "ok"
test "$lane_enabled" = "0"
test "$non_default_lane" = "0"
test "$non_primary_role" = "0"

echo "PASS: production runtime remains default-off"
echo "PASS: Phase 14J-CT Gate B1 result checkpoint smoke passed"
