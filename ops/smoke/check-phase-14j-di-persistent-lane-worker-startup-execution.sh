#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-di-persistent-lane-worker-startup-execution"
DOC="docs/${PHASE}.md"
DB="edge_queue.sqlite3"
SERVICE="edge-queue-controller.service"

echo "=== Phase 14J-DI smoke: persistent lane worker startup execution guard ==="

test -f "$DOC"
echo "PASS: DI doc exists"

for marker in \
  "PHASE_14J_DI_PERSISTENT_LANE_WORKER_STARTUP_EXECUTION_GUARD" \
  "MUTATION_SCOPE=guarded_startup_path_observation_no_production_db_mutation" \
  "APPROVAL_CONFIRMED=yes" \
  "STARTUP_PATH_INSPECTION=performed_sanitized" \
  "SAFE_NO_DB_MUTATION_STARTUP_PATH=no" \
  "PERSISTENT_LANE_WORKER_STARTUP_PERFORMED=no" \
  "STARTUP_EXECUTION_RESULT=blocked_by_no_proven_safe_no_db_mutation_worker_startup_path" \
  "DI_EXECUTION_GUARD_RESULT=blocked_without_mutation" \
  "BLOCK_REASON=no_proven_safe_no_production_db_mutation_worker_startup_path" \
  "PRODUCTION_STATE_UNCHANGED_AFTER_GUARD=verified" \
  "SERVICE_FLAG_REMAINED_UNSET=verified" \
  "JOB_SUMMARY_UNCHANGED=verified" \
  "WORKER_FACTS_UNCHANGED=verified" \
  "STUDY_ROW_REMAINED_ENABLED_OFFLINE=verified" \
  "RUNTIME_ACTIVATION_PERFORMED=no" \
  "NEXT_PHASE_NAME=phase-14j-dj-persistent-lane-worker-startup-contract-clarification" \
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
  "PERSISTENT_LANE_WORKER_STARTUP_EXECUTION_GUARD_RESULT=blocked_without_mutation" \
  "NEXT_SAFE_PHASE=persistent_lane_worker_startup_contract_clarification"; do
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

echo "PASS: production runtime remains unchanged after DI guard"
echo "PASS: Phase 14J-DI startup execution guard smoke passed"
