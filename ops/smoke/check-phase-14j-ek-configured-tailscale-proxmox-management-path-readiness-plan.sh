#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-ek-configured-tailscale-proxmox-management-path-readiness-plan"
DOC="docs/${PHASE}.md"
DB="edge_queue.sqlite3"
SERVICE="edge-queue-controller.service"

echo "=== Phase 14J-EK smoke: configured Tailscale Proxmox management path readiness plan ==="

test -f "$DOC"
echo "PASS: EK doc exists"

for marker in \
  "PHASE_14J_EK_CONFIGURED_TAILSCALE_PROXMOX_MANAGEMENT_PATH_READINESS_PLAN" \
  "MUTATION_SCOPE=docs_smoke_only_configured_tailscale_proxmox_management_path_readiness_plan" \
  "EJ_DECISION_RESULT=accepted" \
  "SECURITY_DECISION=preserve_tailscale_only_proxmox_ssh_management" \
  "USE_CONFIGURED_TAILSCALE_PROXMOX_MANAGEMENT_PATH=yes" \
  "DIRECT_LAN_SSHD_CANDIDATE_USABLE=no" \
  "DO_NOT_REQUIRE_DIRECT_LAN_SSHD=yes" \
  "DO_NOT_OPEN_LAN_FIREWALL_TCP22=yes" \
  "DO_NOT_WEAKEN_PROXMOX_FIREWALL_FOR_AUTOMATION=yes" \
  "DO_NOT_PURSUE_DIRECT_LAN_SSHD_AS_REQUIRED_PATH=yes" \
  "GUARDED_WORKER_START_REMAINS_BLOCKED=yes" \
  "CONFIGURED_TAILSCALE_PROXMOX_MANAGEMENT_PATH_READINESS_PLAN=ready" \
  "CHECK_CONFIGURED_PROXMOX_SSH_TARGET_PRESENT_HASH_ONLY=yes" \
  "CHECK_CONFIGURED_PROXMOX_SSH_TARGET_REACHABLE_READ_ONLY=yes" \
  "CHECK_PROXMOX_IDENTITY_READ_ONLY_HASH_ONLY=yes" \
  "CHECK_PROXMOX_NODE_STATUS_READ_ONLY_SANITIZED=yes" \
  "CHECK_PROXMOX_VM_CT_INVENTORY_READ_ONLY_SANITIZED=yes" \
  "CHECK_NO_PRODUCTION_DB_MUTATION=yes" \
  "CHECK_NO_JOB_MUTATION=yes" \
  "CHECK_NO_SERVICE_ENV_MUTATION=yes" \
  "CHECK_NO_POWER_ENDPOINT_CALL=yes" \
  "CHECK_NO_WORKER_START=yes" \
  "CHECK_NO_RUNTIME_ACTIVATION=yes" \
  "PROXMOX_SERVICE_RESTART_RELOAD=not_allowed" \
  "FIREWALL_MUTATION=not_allowed" \
  "SSH_CONFIG_MUTATION=not_allowed" \
  "LAN_FIREWALL_TCP22_OPEN=not_allowed" \
  "SERVICE_ENV_MUTATION=not_allowed" \
  "POWER_ENDPOINT_CALL=not_allowed" \
  "WORKER_START=not_allowed" \
  "RUNTIME_ACTIVATION=not_allowed" \
  "NO_RAW_CONFIGURED_SSH_TARGET_PRINTING=yes" \
  "HASH_ONLY_CONFIGURED_TARGET_OUTPUT=yes" \
  "REQUIRE_NO_RAW_KEY_PATH_PRINTING=yes" \
  "REQUIRE_NO_FULL_SYSTEMD_ENVIRONMENT_PRINT=yes" \
  "REQUIRE_SHORT_TIMEOUTS=yes" \
  "REQUIRE_SANITIZED_OUTPUT=yes" \
  "NO_SECRETS_PRINTED=yes" \
  "NEXT_PHASE_NAME=phase-14j-el-configured-tailscale-proxmox-management-path-read-only-readiness-diagnostics" \
  "APP_SOURCE_MUTATION=not_performed" \
  "PRODUCTION_DB_MUTATION=not_performed" \
  "JOB_MUTATION=not_performed" \
  "CONTROLLER_SERVICE_RESTART_RELOAD=not_performed" \
  "PROXMOX_SERVICE_RESTART_RELOAD=not_performed" \
  "FIREWALL_MUTATION=not_performed" \
  "SSH_CONFIG_MUTATION=not_performed" \
  "LAN_FIREWALL_TCP22_OPEN=not_performed" \
  "CT101_CALL=not_performed" \
  "MODEL_OLLAMA_CALL=not_performed" \
  "POWER_ENDPOINT_CALL=not_performed" \
  "WORKER_START_PERFORMED=no" \
  "SCHEDULER_LANE_DISPATCH_ACTIVATION=not_performed" \
  "PRIMARY_WORKER_FILTERING_ACTIVATION=not_performed" \
  "PERSISTENT_LANE_WORKER_STARTUP=not_performed" \
  "RUNTIME_ACTIVATION=not_performed" \
  "SERVICE_ENV_MUTATION=not_performed" \
  "PROXMOX_SSH_CALL=not_performed" \
  "PROXMOX_REMOTE_COMMAND_EXECUTION=not_performed" \
  "GITHUB_BRANCH_OR_REPO_DELETE=not_performed" \
  "FULL_SYSTEMD_ENVIRONMENT_PRINTING=not_performed" \
  "RAW_SSH_TARGET_PRINTING=not_performed" \
  "RAW_KEY_PATH_PRINTING=not_performed" \
  "HASH_ONLY_TARGET_OUTPUT=yes" \
  "DO_NOT_RERUN_14J_AG_APPLY_WRAPPER=preserved" \
  "CONFIGURED_TAILSCALE_PROXMOX_MANAGEMENT_PATH_READINESS_PLAN_RESULT=ready_for_read_only_diagnostics" \
  "NEXT_SAFE_PHASE=configured_tailscale_proxmox_management_path_read_only_readiness_diagnostics_requires_approval"; do
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

echo "PASS: production runtime remains unchanged after EK plan"
echo "PASS: Phase 14J-EK configured Tailscale Proxmox management path readiness plan smoke passed"
