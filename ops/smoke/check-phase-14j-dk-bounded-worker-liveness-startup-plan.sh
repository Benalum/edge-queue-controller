#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-dk-bounded-worker-liveness-startup-plan"
DOC="docs/${PHASE}.md"
DB="edge_queue.sqlite3"
SERVICE="edge-queue-controller.service"

echo "=== Phase 14J-DK smoke: bounded worker liveness startup plan ==="

test -f "$DOC"
echo "PASS: DK doc exists"

for marker in \
  "PHASE_14J_DK_BOUNDED_WORKER_LIVENESS_STARTUP_PLAN" \
  "MUTATION_SCOPE=docs_smoke_only_bounded_worker_liveness_startup_plan" \
  "PERSISTENT_LANE_WORKER_STARTUP_CONTRACT_CLARIFICATION_RESULT=completed" \
  "PERSISTENT_LANE_WORKER_STARTUP_CONTRACT=requires_explicit_liveness_db_mutation_allowance" \
  "DI_EXECUTION_GUARD_RESULT=blocked_without_mutation" \
  "BLOCK_REASON=no_proven_safe_no_production_db_mutation_worker_startup_path" \
  "PERSISTENT_LANE_WORKER_STARTUP_PERFORMED=no" \
  "PRODUCTION_STATE_UNCHANGED_AFTER_GUARD=verified" \
  "SERVICE_FLAG_REMAINED_UNSET=verified" \
  "JOB_SUMMARY_UNCHANGED=verified" \
  "WORKER_FACTS_UNCHANGED=verified" \
  "STUDY_ROW_REMAINED_ENABLED_OFFLINE=verified" \
  "RUNTIME_ACTIVATION_PERFORMED=no" \
  "BOUNDED_WORKER_LIVENESS_STARTUP_PLAN=ready_for_explicit_approval_execution" \
  "ALLOW_BOUNDED_WORKER_LIVENESS_DB_MUTATION=yes" \
  "ALLOW_WORKER_LIVENESS_STATE_HEARTBEAT_UPDATES=yes" \
  "ALLOW_PRODUCTION_JOB_MUTATION=no" \
  "ALLOW_SERVICE_RESTART_RELOAD=no" \
  "ALLOW_CT101_CALL=no" \
  "ALLOW_MODEL_OLLAMA_CALL=no" \
  "ALLOW_SCHEDULER_LANE_DISPATCH_ACTIVATION=no" \
  "ALLOW_PRIMARY_WORKER_FILTERING_ACTIVATION=no" \
  "ALLOW_14J_AG_APPLY_WRAPPER_RERUN=no" \
  "REQUIRE_SQLITE_BACKUP_BEFORE_LIVENESS_MUTATION=yes" \
  "REQUIRE_PRE_POST_JOB_SUMMARY_COMPARE=yes" \
  "REQUIRE_PRE_POST_SERVICE_FLAG_COMPARE=yes" \
  "REQUIRE_PRE_POST_WORKER_ROW_COMPARE=yes" \
  "REQUIRE_STOP_OR_ROLLBACK_INSTRUCTIONS=yes" \
  "REQUIRE_EXPLICIT_APPROVAL_BEFORE_EXECUTION=yes" \
  "NEXT_PHASE_NAME=phase-14j-dl-bounded-worker-liveness-startup-execution" \
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
  "BOUNDED_WORKER_LIVENESS_STARTUP_PLAN_RESULT=ready_for_explicit_approval_execution" \
  "NEXT_SAFE_PHASE=bounded_worker_liveness_startup_execution_requires_approval"; do
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

echo "PASS: production runtime remains unchanged after DK"
echo "PASS: Phase 14J-DK bounded worker liveness startup plan smoke passed"
