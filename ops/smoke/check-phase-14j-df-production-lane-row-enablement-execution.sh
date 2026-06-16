#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-df-production-lane-row-enablement-execution"
DOC="docs/${PHASE}.md"
DB="edge_queue.sqlite3"
SERVICE="edge-queue-controller.service"

echo "=== Phase 14J-DF smoke: production lane row enablement execution ==="

test -f "$DOC"
echo "PASS: DF doc exists"

for marker in \
  "PHASE_14J_DF_PRODUCTION_LANE_ROW_ENABLEMENT_EXECUTION" \
  "MUTATION_SCOPE=backup_first_production_db_single_seeded_lane_row_enablement" \
  "APPROVAL_CONFIRMED=yes" \
  "BACKUP_CREATED=yes" \
  "BACKUP_QUICK_CHECK=ok" \
  "ROLLBACK_AVAILABLE=yes" \
  "PRODUCTION_DB_MUTATION=performed_single_seeded_lane_row_disabled_1_to_0" \
  "UPDATED_TABLE=workers" \
  "UPDATED_WORKER_ID=study-lane-metadata-default-off" \
  "UPDATED_ROW_COUNT=1" \
  "UPDATED_FIELD=disabled" \
  "UPDATED_FROM=1" \
  "UPDATED_TO=0" \
  "STATE_REMAINED_OFFLINE=verified" \
  "COMPUTED_HEALTH_REMAINED_OFFLINE=verified" \
  "SERVICE_FLAG_REMAINED_UNSET=verified" \
  "JOB_SUMMARY_UNCHANGED=verified" \
  "WORKER_FACTS_UNCHANGED=verified" \
  "FLAG_ON_OFFLINE_SEEDED_LANE_REMAINS_NOT_ELIGIBLE_AFTER_DISABLED_ZERO=verified" \
  "ROW_METADATA_ENABLED_BUT_RUNTIME_OFFLINE=yes" \
  "ROW_NOT_ELIGIBLE_UNTIL_WORKER_STARTED_AND_HEALTHY=yes" \
  "PRE_DF_DISABLED_ONE_SMOKES_ARE_HISTORICAL_AFTER_DF=yes" \
  "SOURCE_MUTATION=not_performed" \
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
  "PRODUCTION_LANE_ROW_ENABLEMENT_EXECUTION_RESULT=passed_backup_first_single_row_disabled_1_to_0" \
  "NEXT_SAFE_PHASE=production_lane_row_enablement_result_checkpoint_and_pre_df_smoke_compatibility"; do
  grep -F "$marker" "$DOC" >/dev/null
  echo "PASS: marker found: $marker"
done

echo
echo "=== post-DF runtime/default-off guard ==="
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
jobs_summary="$(sqlite3 -csv "file:${PWD}/${DB}?mode=ro" "
SELECT COALESCE(status,'<null>'), COUNT(*)
FROM jobs
GROUP BY COALESCE(status,'<null>')
ORDER BY COALESCE(status,'<null>');
" | tr '\n' ';' | sed 's/;$//')"

echo "service_active=${service_active}"
echo "service_enabled=${service_enabled}"
echo "service_EDGE_PERSISTENT_LANE_WORKERS_ENABLED=${service_flag:-<unset>}"
echo "sqlite_quick_check=${quick_check}"
echo "worker_facts=${worker_facts}"
echo "study_summary=${study_summary}"
echo "jobs_summary=${jobs_summary:-<none>}"

test "$service_active" = "active"
test "$service_enabled" = "enabled"
test -z "$service_flag"
test "$quick_check" = "ok"
test "$worker_facts" = "2,1,1,1"
test "$study_summary" = "lane,study,1,0,offline,offline"
test "$jobs_summary" = "failed,1;forwarded,20;queued,1"

echo "PASS: production runtime remains default-off after DF"
echo "PASS: Phase 14J-DF production lane row enablement execution smoke passed"
