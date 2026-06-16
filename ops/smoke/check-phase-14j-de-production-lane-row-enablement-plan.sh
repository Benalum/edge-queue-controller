#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-de-production-lane-row-enablement-plan"
DOC="docs/${PHASE}.md"
DB="edge_queue.sqlite3"
SERVICE="edge-queue-controller.service"

echo "=== Phase 14J-DE smoke: production lane row enablement plan ==="

test -f "$DOC"
echo "PASS: DE doc exists"

for marker in \
  "PHASE_14J_DE_PRODUCTION_LANE_ROW_ENABLEMENT_PLAN" \
  "MUTATION_SCOPE=docs_smoke_only_production_lane_row_enablement_plan" \
  "BOUNDED_SERVICE_FLAG_ACTIVATION_RESULT_CHECKPOINT=completed" \
  "BOUNDED_SERVICE_FLAG_ACTIVATION_EXECUTION_RESULT=passed_flag_on_observation_and_rollback" \
  "GATE_B4_BOUNDED_CONTROLLER_FLAG_ROLLBACK_RESULT=passed" \
  "POST_ROLLBACK_LANE_FLAG_UNSET=verified" \
  "DISABLED_OFFLINE_SEEDED_LANE_SAFETY_WITH_FLAG_ON=verified" \
  "RUNTIME_ACTIVATION_AFTER_DC=not_active" \
  "PRODUCTION_LANE_ROW_ENABLEMENT_PLAN=ready_for_explicit_approval_execution" \
  "target_table=workers" \
  "target_worker_id=study-lane-metadata-default-off" \
  "planned_change=disabled_1_to_0_only" \
  "state_must_remain=offline" \
  "computed_health_must_remain=offline" \
  "service_flag_must_remain_unset=yes" \
  "row_is_metadata_enabled_but_runtime_offline=yes" \
  "row_must_remain_not_eligible_until_worker_is_started_and_healthy=yes" \
  "SQLITE_BACKUP_REQUIRED_BEFORE_DB_MUTATION=yes" \
  "BACKUP_QUICK_CHECK_REQUIRED=yes" \
  "ROLLBACK_AVAILABLE_REQUIRED=yes" \
  "PRE_AND_POST_JOB_SUMMARY_COMPARE_REQUIRED=yes" \
  "PRE_AND_POST_SERVICE_FLAG_COMPARE_REQUIRED=yes" \
  "NEXT_PHASE_NAME=phase-14j-df-production-lane-row-enablement-execution" \
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
  "PRODUCTION_LANE_ROW_ENABLEMENT_PLAN_RESULT=ready_for_explicit_approval_execution" \
  "NEXT_SAFE_PHASE=production_lane_row_enablement_execution_requires_approval"; do
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
echo "study_summary=${study_summary}"

test "$service_active" = "active"
test "$service_enabled" = "enabled"
test -z "$service_flag"
test "$quick_check" = "ok"
test "$worker_facts" = "2,1,1,1"
test "$study_summary" = "lane,study,1,1,offline,offline"

echo "PASS: production runtime remains default-off after DE plan"
echo "PASS: Phase 14J-DE production lane row enablement plan smoke passed"
