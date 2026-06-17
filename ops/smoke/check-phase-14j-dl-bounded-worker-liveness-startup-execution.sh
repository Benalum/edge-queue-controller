#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-dl-bounded-worker-liveness-startup-execution"
DOC="docs/${PHASE}.md"
DB="edge_queue.sqlite3"
SERVICE="edge-queue-controller.service"

echo "=== Phase 14J-DL smoke: bounded worker liveness startup execution ==="

test -f "$DOC"
echo "PASS: DL doc exists"

for marker in \
  "PHASE_14J_DL_BOUNDED_WORKER_LIVENESS_STARTUP_EXECUTION" \
  "MUTATION_SCOPE=bounded_worker_liveness_startup_execution_with_guarded_liveness_db_allowance" \
  "APPROVAL_CONFIRMED=yes" \
  "BACKUP_CREATED=yes" \
  "BACKUP_QUICK_CHECK=ok" \
  "ROLLBACK_AVAILABLE=yes" \
  "SAFE_STARTUP_OBSERVATION_PATH=no" \
  "LIVENESS_DB_MUTATION_PERFORMED=no" \
  "PERSISTENT_LANE_WORKER_STARTUP_PERFORMED=no" \
  "STARTUP_EXECUTION_RESULT=blocked_by_no_allowed_non_ct101_non_model_startup_observation_path" \
  "DL_EXECUTION_GUARD_RESULT=blocked_without_liveness_mutation" \
  "BLOCK_REASON=no_allowed_non_ct101_non_model_startup_observation_path" \
  "PRODUCTION_STATE_UNCHANGED_AFTER_GUARD=verified" \
  "SERVICE_FLAG_REMAINED_UNSET=verified" \
  "JOB_SUMMARY_UNCHANGED=verified" \
  "WORKER_FACTS_UNCHANGED=verified" \
  "STUDY_ROW_REMAINED_ENABLED_OFFLINE=verified" \
  "RUNTIME_ACTIVATION_PERFORMED=no" \
  "NEXT_PHASE_NAME=phase-14j-dm-worker-startup-execution-contract-extension-plan" \
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
  "BOUNDED_WORKER_LIVENESS_STARTUP_EXECUTION_RESULT=blocked_without_liveness_mutation" \
  "NEXT_SAFE_PHASE=worker_startup_execution_contract_extension_plan"; do
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

echo "PASS: production runtime remains unchanged after DL guard"
echo "PASS: Phase 14J-DL bounded worker liveness startup execution smoke passed"
