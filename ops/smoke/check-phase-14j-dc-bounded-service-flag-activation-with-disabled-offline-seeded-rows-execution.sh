#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-dc-bounded-service-flag-activation-with-disabled-offline-seeded-rows-execution"
DOC="docs/${PHASE}.md"
DB="edge_queue.sqlite3"
SERVICE="edge-queue-controller.service"

echo "=== Phase 14J-DC smoke: bounded service flag activation/rollback execution ==="

test -f "$DOC"
echo "PASS: DC doc exists"

for marker in \
  "PHASE_14J_DC_BOUNDED_SERVICE_FLAG_ACTIVATION_WITH_DISABLED_OFFLINE_SEEDED_ROWS_EXECUTION" \
  "MUTATION_SCOPE=bounded_controller_service_flag_activation_rollback_observation" \
  "APPROVAL_CONFIRMED=yes" \
  "TEMPORARY_CONTROLLER_SERVICE_FLAG_SET=verified" \
  "service_EDGE_PERSISTENT_LANE_WORKERS_ENABLED_on=EDGE_PERSISTENT_LANE_WORKERS_ENABLED=1" \
  "FLAG_ON_DISABLED_OFFLINE_SEEDED_LANE_NOT_ELIGIBLE=verified" \
  "DB_FACTS_UNCHANGED_WHILE_FLAG_ON=verified" \
  "JOB_SUMMARY_UNCHANGED_WHILE_FLAG_ON=verified" \
  "TEMPORARY_CONTROLLER_SERVICE_FLAG_ROLLED_BACK=verified" \
  "DB_FACTS_UNCHANGED_AFTER_ROLLBACK=verified" \
  "JOB_SUMMARY_UNCHANGED_AFTER_ROLLBACK=verified" \
  "SOURCE_MUTATION=not_performed" \
  "PRODUCTION_DB_MUTATION=not_performed" \
  "JOB_MUTATION=not_performed" \
  "SERVICE_RESTART_RELOAD=performed_bounded_controller_only" \
  "CT101_CALL=not_performed" \
  "MODEL_OLLAMA_CALL=not_performed" \
  "SCHEDULER_LANE_DISPATCH_ACTIVATION=not_performed" \
  "PRIMARY_WORKER_FILTERING_ACTIVATION=not_performed" \
  "PERSISTENT_LANE_WORKER_STARTUP=not_performed" \
  "RUNTIME_ACTIVATION=beyond_temporary_controller_flag_observation_not_performed" \
  "DO_NOT_RERUN_14J_AG_APPLY_WRAPPER=preserved" \
  "NO_SECRETS_PRINTED=yes" \
  "BOUNDED_SERVICE_FLAG_ACTIVATION_EXECUTION_RESULT=passed_flag_on_observation_and_rollback" \
  "NEXT_SAFE_PHASE=bounded_service_flag_activation_result_checkpoint"; do
  grep -F "$marker" "$DOC" >/dev/null
  echo "PASS: marker found: $marker"
done

echo
echo "=== post-rollback runtime/default-off seeded metadata guard ==="
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

echo "PASS: production runtime remains default-off after DC rollback"
echo "PASS: Phase 14J-DC bounded service flag execution smoke passed"
