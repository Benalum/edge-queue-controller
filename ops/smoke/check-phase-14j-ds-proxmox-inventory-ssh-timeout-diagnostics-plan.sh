#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-ds-proxmox-inventory-ssh-timeout-diagnostics-plan"
DOC="docs/${PHASE}.md"
DB="edge_queue.sqlite3"
SERVICE="edge-queue-controller.service"

echo "=== Phase 14J-DS smoke: Proxmox inventory SSH timeout diagnostics plan ==="

test -f "$DOC"
echo "PASS: DS doc exists"

for marker in \
  "PHASE_14J_DS_PROXMOX_INVENTORY_SSH_TIMEOUT_DIAGNOSTICS_PLAN" \
  "MUTATION_SCOPE=docs_smoke_only_proxmox_inventory_ssh_timeout_diagnostics_plan" \
  "CONTROLLER_POWER_START_WORKER_DRY_RUN_504_READ_ONLY_DIAGNOSTICS_RESULT=completed" \
  "DN_RESPONSE_DETAIL=Timed out while querying Proxmox inventory over SSH." \
  "DN_DRY_RUN_HTTP_STATUS=504" \
  "DN_DRY_RUN_CALL_RESULT=completed_http_non_2xx" \
  "DRY_RUN_504_ROOT_CAUSE_AREA=proxmox_inventory_over_ssh_timeout" \
  "NEXT_DIAGNOSTIC_AREA=proxmox_inventory_ssh_timeout_read_only" \
  "POWER_START_WORKER_PLAN_USES_EDGE_PROXMOX_SSH_TARGET=yes" \
  "POWER_START_WORKER_PLAN_QUERIES_PROXMOX_INVENTORY=yes" \
  "PROXMOX_INVENTORY_SSH_TIMEOUT_DIAGNOSTICS_PLAN=ready_for_explicit_read_only_diagnostics" \
  "CHECK_EDGE_PROXMOX_SSH_TARGET_PRESENT_REDACTED=yes" \
  "CHECK_SSH_REACHABILITY_WITH_SHORT_TIMEOUT=yes" \
  "CHECK_PROXMOX_INVENTORY_COMMAND_WITH_SHORT_TIMEOUT=yes" \
  "ALLOW_POWER_ENDPOINT_CALL=no" \
  "ALLOW_EXECUTE_POWER_ENDPOINT_CALL=no" \
  "ALLOW_WORKER_START=no" \
  "ALLOW_PRODUCTION_DB_MUTATION=no" \
  "ALLOW_PRODUCTION_JOB_MUTATION=no" \
  "ALLOW_SERVICE_RESTART_RELOAD=no" \
  "ALLOW_CT101_CALL=no" \
  "ALLOW_MODEL_OLLAMA_CALL=no" \
  "ALLOW_SCHEDULER_LANE_DISPATCH_ACTIVATION=no" \
  "ALLOW_PRIMARY_WORKER_FILTERING_ACTIVATION=no" \
  "ALLOW_RUNTIME_ACTIVATION=no" \
  "ALLOW_APP_SOURCE_MUTATION=no" \
  "ALLOW_GITHUB_BRANCH_OR_REPO_DELETE=no" \
  "REQUIRE_SANITIZED_OUTPUT=yes" \
  "REQUIRE_NO_SECRET_PRINTING=yes" \
  "REQUIRE_SHORT_TIMEOUTS=yes" \
  "REQUIRE_NO_FULL_SYSTEMD_ENVIRONMENT_PRINT=yes" \
  "GUARDED_WORKER_START_REMAINS_BLOCKED=yes" \
  "PROXMOX_INVENTORY_SSH_TIMEOUT_DIAGNOSIS_REQUIRED=yes" \
  "NEXT_PHASE_NAME=phase-14j-dt-proxmox-inventory-ssh-timeout-read-only-diagnostics" \
  "APP_SOURCE_MUTATION=not_performed" \
  "PRODUCTION_DB_MUTATION=not_performed" \
  "JOB_MUTATION=not_performed" \
  "SERVICE_RESTART_RELOAD=not_performed" \
  "CT101_CALL=not_performed" \
  "MODEL_OLLAMA_CALL=not_performed" \
  "POWER_ENDPOINT_CALL=not_performed" \
  "PROXMOX_SSH_CALL=not_performed" \
  "WORKER_START_PERFORMED=no" \
  "SCHEDULER_LANE_DISPATCH_ACTIVATION=not_performed" \
  "PRIMARY_WORKER_FILTERING_ACTIVATION=not_performed" \
  "PERSISTENT_LANE_WORKER_STARTUP=not_performed" \
  "RUNTIME_ACTIVATION=not_performed" \
  "DO_NOT_RERUN_14J_AG_APPLY_WRAPPER=preserved" \
  "NO_SECRETS_PRINTED=yes" \
  "PROXMOX_INVENTORY_SSH_TIMEOUT_DIAGNOSTICS_PLAN_RESULT=ready_for_explicit_read_only_diagnostics" \
  "NEXT_SAFE_PHASE=proxmox_inventory_ssh_timeout_read_only_diagnostics_requires_approval"; do
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

echo "PASS: production runtime remains unchanged after DS plan"
echo "PASS: Phase 14J-DS Proxmox inventory SSH timeout diagnostics plan smoke passed"
