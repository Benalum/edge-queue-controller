#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-dt-proxmox-inventory-ssh-timeout-read-only-diagnostics"
DOC="docs/${PHASE}.md"
DB="edge_queue.sqlite3"
SERVICE="edge-queue-controller.service"

echo "=== Phase 14J-DT smoke: Proxmox inventory SSH timeout read-only diagnostics ==="

test -f "$DOC"
echo "PASS: DT doc exists"

for marker in \
  "PHASE_14J_DT_PROXMOX_INVENTORY_SSH_TIMEOUT_READ_ONLY_DIAGNOSTICS" \
  "MUTATION_SCOPE=docs_smoke_only_proxmox_inventory_ssh_timeout_read_only_diagnostics_result" \
  "APPROVAL_CONFIRMED=yes" \
  "DT_DIAGNOSTICS_RESULT=completed_read_only" \
  "DT_MUTATION_RESULT=none" \
  "EDGE_PROXMOX_SSH_TARGET_PRESENT=yes" \
  "EDGE_POWER_TARGET_MAP_PRESENT=yes" \
  "EDGE_POWER_TARGET_MAP_MENTIONS_LLMS_OLLAMA=yes" \
  "SSH_HOST_RESOLUTION_RC=0" \
  "SSH_HOST_RESOLUTION_RESULT=resolved" \
  "TAILSCALE_STATUS_RC=0" \
  "TAILSCALE_BACKEND_STATE=Running" \
  "SSH_REACHABILITY_TRUE_RC=255" \
  "SSH_PVESH_PRESENT_RC=255" \
  "SSH_PROXMOX_INVENTORY_RC=255" \
  "INVENTORY_OUTPUT_JSON_ATTEMPTED=yes" \
  "INVENTORY_OUTPUT_SIZE=0" \
  "INVENTORY_JSON_PARSE_RESULT=failed" \
  "INVENTORY_JSON_PARSE_ERROR=JSONDecodeError" \
  "TARGET_MAP_LLMS_OLLAMA_MAPPING_PRESENT=yes" \
  "TARGET_MAP_LLMS_OLLAMA_KIND=ct" \
  "TARGET_MAP_LLMS_OLLAMA_VMID_PRESENT=yes" \
  "POWER_START_WORKER_PLAN_FOUND=yes" \
  "POWER_START_WORKER_PLAN_USES_EDGE_PROXMOX_SSH_TARGET=yes" \
  "POWER_START_WORKER_PLAN_DECLARES_DRY_RUN_NO_START=yes" \
  "DT_NARROWED_ROOT_CAUSE_AREA=ssh_connection_or_auth_path_failure_before_inventory_output" \
  "PROXMOX_INVENTORY_TIMEOUT_CAUSE_REFINED=ssh_rc_255_before_inventory_command_output" \
  "GUARDED_WORKER_START_REMAINS_BLOCKED=yes" \
  "SERVICE_FLAG_REMAINED_UNSET=verified" \
  "SQLITE_QUICK_CHECK_AFTER=ok" \
  "WORKER_FACTS_UNCHANGED=verified" \
  "STUDY_ROW_REMAINED_ENABLED_OFFLINE=verified" \
  "JOB_SUMMARY_UNCHANGED=verified" \
  "PRODUCTION_STATE_UNCHANGED_AFTER_DIAGNOSTICS=verified" \
  "NEXT_PHASE_NAME=phase-14j-du-ssh-rc-255-diagnostics-plan" \
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
  "GITHUB_BRANCH_OR_REPO_DELETE=not_performed" \
  "FULL_SYSTEMD_ENVIRONMENT_PRINTING=not_performed" \
  "DO_NOT_RERUN_14J_AG_APPLY_WRAPPER=preserved" \
  "NO_SECRETS_PRINTED=yes" \
  "PROXMOX_INVENTORY_SSH_TIMEOUT_READ_ONLY_DIAGNOSTICS_RESULT=completed" \
  "NEXT_SAFE_PHASE=ssh_rc_255_diagnostics_plan"; do
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

echo "PASS: production runtime remains unchanged after DT checkpoint"
echo "PASS: Phase 14J-DT Proxmox inventory SSH timeout read-only diagnostics smoke passed"
