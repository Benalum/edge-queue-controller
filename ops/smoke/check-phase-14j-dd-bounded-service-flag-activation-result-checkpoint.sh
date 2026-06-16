#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-dd-bounded-service-flag-activation-result-checkpoint"
DOC="docs/${PHASE}.md"
DB="edge_queue.sqlite3"
SERVICE="edge-queue-controller.service"

echo "=== Phase 14J-DD smoke: bounded service flag activation result checkpoint ==="

test -f "$DOC"
echo "PASS: DD doc exists"

for marker in \
  "PHASE_14J_DD_BOUNDED_SERVICE_FLAG_ACTIVATION_RESULT_CHECKPOINT" \
  "MUTATION_SCOPE=docs_smoke_only_bounded_service_flag_activation_result_checkpoint" \
  "BOUNDED_SERVICE_FLAG_ACTIVATION_EXECUTION_RESULT=passed_flag_on_observation_and_rollback" \
  "TEMPORARY_CONTROLLER_SERVICE_FLAG_SET=verified" \
  "FLAG_ON_DISABLED_OFFLINE_SEEDED_LANE_NOT_ELIGIBLE=verified" \
  "TEMPORARY_CONTROLLER_SERVICE_FLAG_ROLLED_BACK=verified" \
  "DB_FACTS_UNCHANGED_WHILE_FLAG_ON=verified" \
  "JOB_SUMMARY_UNCHANGED_WHILE_FLAG_ON=verified" \
  "DB_FACTS_UNCHANGED_AFTER_ROLLBACK=verified" \
  "JOB_SUMMARY_UNCHANGED_AFTER_ROLLBACK=verified" \
  "POST_ROLLBACK_CONTROLLER_SERVICE_ACTIVE=verified" \
  "POST_ROLLBACK_LANE_FLAG_UNSET=verified" \
  "POST_ROLLBACK_SEEDED_METADATA_SAFE=verified" \
  "GATE_B4_BOUNDED_CONTROLLER_FLAG_ROLLBACK_RESULT=passed" \
  "RUNTIME_ACTIVATION_AFTER_DC=not_active" \
  "SERVICE_FLAG_ACTIVATION_ROLLBACK_EVIDENCE=complete" \
  "DISABLED_OFFLINE_SEEDED_LANE_SAFETY_WITH_FLAG_ON=verified" \
  "NEXT_PHASE_NAME=phase-14j-de-production-lane-row-enablement-plan" \
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
  "BOUNDED_SERVICE_FLAG_ACTIVATION_RESULT_CHECKPOINT=completed" \
  "NEXT_SAFE_PHASE=production_lane_row_enablement_plan"; do
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

echo "PASS: production runtime remains default-off after DD"
echo "PASS: Phase 14J-DD bounded service flag result checkpoint smoke passed"
