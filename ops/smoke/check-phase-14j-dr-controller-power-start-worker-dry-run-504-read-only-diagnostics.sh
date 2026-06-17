#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-dr-controller-power-start-worker-dry-run-504-read-only-diagnostics"
DOC="docs/${PHASE}.md"
DB="edge_queue.sqlite3"
SERVICE="edge-queue-controller.service"

echo "=== Phase 14J-DR smoke: 504 read-only diagnostics result checkpoint ==="

test -f "$DOC"
echo "PASS: DR doc exists"

for marker in \
  "PHASE_14J_DR_CONTROLLER_POWER_START_WORKER_DRY_RUN_504_READ_ONLY_DIAGNOSTICS" \
  "MUTATION_SCOPE=docs_smoke_only_504_read_only_diagnostics_result_checkpoint" \
  "DR_DIAGNOSTICS_RESULT=completed_read_only_concise" \
  "DR_MUTATION_RESULT=none" \
  "DR_PRIOR_TIMEOUT_CAUSE=large_output_or_pipe_sigpipe" \
  "DN_RESPONSE_EXISTS=yes" \
  "DN_RESPONSE_JSON=yes" \
  "DN_RESPONSE_TOP_KEYS=detail" \
  "DN_RESPONSE_DETAIL=Timed out while querying Proxmox inventory over SSH." \
  "DN_SUMMARY_EXISTS=yes" \
  "DN_DRY_RUN_CALL_RESULT=completed_http_non_2xx" \
  "DN_DRY_RUN_HTTP_STATUS=504" \
  "POWER_START_WORKER_PLAN_FOUND=yes" \
  "POWER_START_WORKER_PLAN_USES_EDGE_PROXMOX_SSH_TARGET=yes" \
  "POWER_START_WORKER_PLAN_HAS_DRY_RUN_NOTE=yes" \
  "POWER_START_WORKER_PLAN_QUERIES_PROXMOX_INVENTORY=yes" \
  "POWER_START_WORKER_PLAN_RETURNS_ELIGIBLE=yes" \
  "POWER_START_WORKER_PLAN_RAISES_HTTP_EXCEPTION=yes" \
  "POWER_START_WORKER_PLAN_DECLARED_NO_WORKER_START=yes" \
  "JOURNAL_RELEVANT_MATCH_COUNT=0" \
  "SERVICE_FLAG_REMAINED_UNSET=verified" \
  "SQLITE_QUICK_CHECK_AFTER=ok" \
  "JOB_SUMMARY_UNCHANGED=verified" \
  "WORKER_FACTS_UNCHANGED=verified" \
  "STUDY_ROW_REMAINED_ENABLED_OFFLINE=verified" \
  "PRODUCTION_STATE_UNCHANGED_AFTER_DIAGNOSTICS=verified" \
  "GUARDED_WORKER_START_REMAINS_BLOCKED=yes" \
  "DRY_RUN_504_ROOT_CAUSE_AREA=proxmox_inventory_over_ssh_timeout" \
  "NEXT_DIAGNOSTIC_AREA=proxmox_inventory_ssh_timeout_read_only" \
  "NEXT_PHASE_NAME=phase-14j-ds-proxmox-inventory-ssh-timeout-diagnostics-plan" \
  "APP_SOURCE_MUTATION=not_performed" \
  "PRODUCTION_DB_MUTATION=not_performed" \
  "JOB_MUTATION=not_performed" \
  "SERVICE_RESTART_RELOAD=not_performed" \
  "CT101_CALL=not_performed" \
  "MODEL_OLLAMA_CALL=not_performed" \
  "POWER_ENDPOINT_CALL=not_performed" \
  "WORKER_START_PERFORMED=no" \
  "SCHEDULER_LANE_DISPATCH_ACTIVATION=not_performed" \
  "PRIMARY_WORKER_FILTERING_ACTIVATION=not_performed" \
  "PERSISTENT_LANE_WORKER_STARTUP=not_performed" \
  "RUNTIME_ACTIVATION=not_performed" \
  "DO_NOT_RERUN_14J_AG_APPLY_WRAPPER=preserved" \
  "NO_SECRETS_PRINTED=yes" \
  "CONTROLLER_POWER_START_WORKER_DRY_RUN_504_READ_ONLY_DIAGNOSTICS_RESULT=completed" \
  "NEXT_SAFE_PHASE=proxmox_inventory_ssh_timeout_diagnostics_plan"; do
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

echo "PASS: production runtime remains unchanged after DR checkpoint"
echo "PASS: Phase 14J-DR 504 read-only diagnostics smoke passed"
