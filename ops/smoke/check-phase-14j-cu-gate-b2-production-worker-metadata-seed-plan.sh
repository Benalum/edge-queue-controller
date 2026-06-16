#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-cu-gate-b2-production-worker-metadata-seed-plan"
DOC="docs/${PHASE}.md"
DB="edge_queue.sqlite3"
SERVICE="edge-queue-controller.service"

echo "=== Phase 14J-CU smoke: Gate B2 production worker metadata seed plan ==="

test -f "$DOC"
echo "PASS: CU doc exists"

for marker in \
  "PHASE_14J_CU_GATE_B2_PRODUCTION_WORKER_METADATA_SEED_PLAN" \
  "MUTATION_SCOPE=docs_smoke_only_gate_b2_production_worker_metadata_seed_plan" \
  "GATE_B1_RESULT=passed_temp_db_worker_availability_metadata" \
  "GATE_B1_TEMP_DB_WORKER_AVAILABILITY_SMOKE_RESULT=passed" \
  "PRODUCTION_DB_UNCHANGED_AFTER_TEMP_DB_SMOKE=verified" \
  "DEFAULT_OFF_FILTER_PASSTHROUGH_WITH_TEMP_DB=verified" \
  "TEMP_DB_LANE_REQUIRED_ACCEPTS_ONLY_ELIGIBLE_STUDY_WORKER=verified" \
  "TEMP_DB_ACCEPTS_LANE_JOBS_FALSE_REJECTED=verified" \
  "TEMP_DB_NO_LANE_JOB_DEFAULT_PATH_PASSTHROUGH=verified" \
  "TEMP_DB_LANE_REQUIRED_WITH_NO_ELIGIBLE_WORKER_FAILS_SAFE=verified" \
  "GATE_B2_PLAN=guarded_backup_first_default_off_production_worker_metadata_seed" \
  "PRIMARY_METADATA_ROW=primary_default_worker_metadata" \
  "STUDY_LANE_METADATA_ROW=study_lane_worker_metadata_default_off" \
  "BACKUP_REQUIRED_BEFORE_PRODUCTION_DB_MUTATION=yes" \
  "ROLLBACK_PLAN_REQUIRED=yes" \
  "ROLLBACK_SHOULD_RESTORE_BACKUP_OR_DELETE_ONLY_SEEDED_ROWS=yes" \
  "POST_SEED_QUICK_CHECK_REQUIRED=yes" \
  "POST_SEED_DEFAULT_OFF_GUARD_REQUIRED=yes" \
  "POST_SEED_JOB_SUMMARY_UNCHANGED_REQUIRED=yes" \
  "NEXT_PHASE_NAME=phase-14j-cv-gate-b2-guarded-production-worker-metadata-seed" \
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
  "GATE_B2_PRODUCTION_WORKER_METADATA_SEED_PLAN_RESULT=ready_for_guarded_backup_first_seed" \
  "NEXT_SAFE_PHASE=gate_b2_guarded_production_worker_metadata_seed"; do
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
echo "PASS: Phase 14J-CU Gate B2 seed plan smoke passed"
