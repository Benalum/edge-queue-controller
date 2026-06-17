#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-ei-proxmox-sshd-timeout-investigation-plan"
DOC="docs/${PHASE}.md"
DB="edge_queue.sqlite3"
SERVICE="edge-queue-controller.service"

echo "=== Phase 14J-EI smoke: Proxmox sshd timeout investigation plan ==="

test -f "$DOC"
echo "PASS: EI doc exists"

for marker in \
  "PHASE_14J_EI_PROXMOX_SSHD_TIMEOUT_INVESTIGATION_PLAN" \
  "MUTATION_SCOPE=docs_smoke_only_proxmox_sshd_timeout_investigation_plan" \
  "PROXMOX_LAN_SSHD_REACHABILITY_READ_ONLY_DIAGNOSTICS_RESULT=completed_local_route_exists_but_tcp22_timeout" \
  "EH_NARROWED_RESULT=local_route_exists_but_tcp22_timeout" \
  "LOCAL_ROUTE_TO_CANDIDATE_PRESENT=yes" \
  "WIREGUARD_HOME_LINK_PRESENT_OBSERVED=yes" \
  "TCP22_TIMEOUT_CONFIRMED=yes" \
  "GUARDED_WORKER_START_REMAINS_BLOCKED=yes" \
  "PROXMOX_SSHD_TIMEOUT_INVESTIGATION_PLAN=ready" \
  "PROXMOX_SSHD_SERVICE_INACTIVE_OR_BOUND_UNEXPECTEDLY=possible" \
  "PROXMOX_HOST_FIREWALL_OR_PVE_FIREWALL_BLOCKING_TCP22=possible" \
  "LAN_OR_VPN_ROUTE_EXISTS_BUT_RETURN_PATH_BLOCKED=possible" \
  "CONTROLLER_WIREGUARD_HOME_INTERFACE_PRESENT_BUT_NOT_ACTIVE_FOR_ROUTE=possible" \
  "SSHD_LISTENING_ONLY_ON_TAILSCALE_OR_DIFFERENT_INTERFACE=possible" \
  "CANDIDATE_LAN_PATH_VALID_BUT_TCP22_FILTERED=possible" \
  "CHECK_PROXMOX_SSHD_SERVICE_STATUS_READ_ONLY=yes" \
  "CHECK_PROXMOX_SSHD_LISTEN_SOCKETS_READ_ONLY=yes" \
  "CHECK_PROXMOX_FIREWALL_STATUS_READ_ONLY=yes" \
  "CHECK_PROXMOX_HOST_ROUTE_INTERFACE_SUMMARY_REDACTED=yes" \
  "CHECK_CONTROLLER_TO_CANDIDATE_TCP22_RETEST=yes" \
  "CHECK_NO_PRODUCTION_DB_MUTATION=yes" \
  "CHECK_NO_JOB_MUTATION=yes" \
  "CHECK_NO_SERVICE_ENV_MUTATION=yes" \
  "CHECK_NO_POWER_ENDPOINT_CALL=yes" \
  "CHECK_NO_WORKER_START=yes" \
  "CHECK_NO_RUNTIME_ACTIVATION=yes" \
  "PROXMOX_SSHD_RESTART=not_allowed" \
  "FIREWALL_MUTATION=not_allowed" \
  "SSH_CONFIG_MUTATION=not_allowed" \
  "SERVICE_ENV_MUTATION=not_allowed" \
  "POWER_ENDPOINT_CALL=not_allowed" \
  "WORKER_START=not_allowed" \
  "RUNTIME_ACTIVATION=not_allowed" \
  "DO_NOT_PASTE_RAW_CANDIDATE_IN_CHAT=yes" \
  "SET_CANDIDATE_AS_LOCAL_SHELL_VARIABLE_ONLY=yes" \
  "HASH_ONLY_CANDIDATE_OUTPUT=yes" \
  "REQUIRE_NO_RAW_SSH_TARGET_PRINTING=yes" \
  "REQUIRE_NO_RAW_KEY_PATH_PRINTING=yes" \
  "REQUIRE_NO_FULL_SYSTEMD_ENVIRONMENT_PRINT=yes" \
  "REQUIRE_SHORT_TIMEOUTS=yes" \
  "REQUIRE_SANITIZED_OUTPUT=yes" \
  "NEXT_PHASE_NAME=phase-14j-ej-proxmox-sshd-timeout-read-only-diagnostics" \
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
  "SERVICE_ENV_MUTATION=not_performed" \
  "PROXMOX_SSH_CALL=not_performed" \
  "PROXMOX_REMOTE_COMMAND_EXECUTION=not_performed" \
  "GITHUB_BRANCH_OR_REPO_DELETE=not_performed" \
  "FULL_SYSTEMD_ENVIRONMENT_PRINTING=not_performed" \
  "RAW_SSH_TARGET_PRINTING=not_performed" \
  "RAW_KEY_PATH_PRINTING=not_performed" \
  "HASH_ONLY_TARGET_COMPARISON=yes" \
  "HASH_ONLY_HOSTKEY_OUTPUT=yes" \
  "DO_NOT_RERUN_14J_AG_APPLY_WRAPPER=preserved" \
  "NO_SECRETS_PRINTED=yes" \
  "PROXMOX_SSHD_TIMEOUT_INVESTIGATION_PLAN_RESULT=ready_for_read_only_diagnostics" \
  "NEXT_SAFE_PHASE=proxmox_sshd_timeout_read_only_diagnostics_requires_approval"; do
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

echo "PASS: production runtime remains unchanged after EI plan"
echo "PASS: Phase 14J-EI Proxmox sshd timeout investigation plan smoke passed"
