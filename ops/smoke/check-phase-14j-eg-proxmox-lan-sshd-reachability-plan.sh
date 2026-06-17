#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-eg-proxmox-lan-sshd-reachability-plan"
DOC="docs/${PHASE}.md"
DB="edge_queue.sqlite3"
SERVICE="edge-queue-controller.service"

echo "=== Phase 14J-EG smoke: Proxmox LAN sshd reachability plan ==="

test -f "$DOC"
echo "PASS: EG doc exists"

for marker in \
  "PHASE_14J_EG_PROXMOX_LAN_SSHD_REACHABILITY_PLAN" \
  "MUTATION_SCOPE=docs_smoke_only_proxmox_lan_sshd_reachability_plan" \
  "DIRECT_PROXMOX_SSHD_CANDIDATE_READ_ONLY_DIAGNOSTICS_SECOND_RETRY_RESULT=completed_candidate_differs_but_tcp22_unreachable" \
  "EF_NARROWED_RESULT=direct_candidate_differs_but_tcp22_unreachable_from_controller" \
  "DIRECT_PROXMOX_SSHD_CANDIDATE_DIFFERENT_FROM_TAILSCALE_ENDPOINT=yes" \
  "CANDIDATE_TCP22_RESULT=connect_timeout" \
  "CANDIDATE_STATUS=candidate_not_reachable_on_tcp22" \
  "PROXMOX_LAN_SSHD_REACHABILITY_PLAN=ready" \
  "CHECK_LOCAL_CONTROLLER_ROUTE_TO_CANDIDATE_HASH_ONLY=yes" \
  "CHECK_LOCAL_INTERFACE_SUMMARY_REDACTED=yes" \
  "CHECK_LOCAL_DEFAULT_ROUTE_SUMMARY_REDACTED=yes" \
  "CHECK_WIREGUARD_HOME_INTERFACE_STATUS_REDACTED=yes" \
  "CHECK_TAILSCALE_STATUS_REDACTED=yes" \
  "CHECK_CANDIDATE_TCP22_BANNER_HASH_ONLY=yes" \
  "CHECK_CANDIDATE_KEYSCAN_HASH_ONLY=yes" \
  "CHECK_NO_REMOTE_COMMAND_EXECUTION=yes" \
  "CHECK_NO_SERVICE_ENV_MUTATION=yes" \
  "CHECK_NO_POWER_ENDPOINT_CALL=yes" \
  "DO_NOT_PASTE_RAW_CANDIDATE_IN_CHAT=yes" \
  "SET_CANDIDATE_AS_LOCAL_SHELL_VARIABLE_ONLY=yes" \
  "HASH_ONLY_CANDIDATE_OUTPUT=yes" \
  "REQUIRE_NO_RAW_SSH_TARGET_PRINTING=yes" \
  "REQUIRE_NO_RAW_KEY_PATH_PRINTING=yes" \
  "REQUIRE_NO_FULL_SYSTEMD_ENVIRONMENT_PRINT=yes" \
  "REQUIRE_SHORT_TIMEOUTS=yes" \
  "REQUIRE_SANITIZED_OUTPUT=yes" \
  "CONTROLLER_NOT_ON_HOME_LAN_OR_VPN=possible" \
  "HOME_WIREGUARD_NOT_UP_OR_NOT_ROUTING=possible" \
  "LAN_ROUTE_MISSING_FROM_CONTROLLER=possible" \
  "HOST_FIREWALL_OR_NETWORK_FILTERING_TCP22=possible" \
  "PROXMOX_SSHD_BOUND_TO_DIFFERENT_INTERFACE=possible" \
  "WRONG_PRIVATE_NETWORK_PATH=possible" \
  "TAILSCALE_SSH_ENDPOINT_STILL_SEPARATE_FROM_NATIVE_SSHD=confirmed_context" \
  "NEXT_PHASE_NAME=phase-14j-eh-proxmox-lan-sshd-reachability-read-only-diagnostics" \
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
  "PROXMOX_LAN_SSHD_REACHABILITY_PLAN_RESULT=ready_for_read_only_diagnostics" \
  "NEXT_SAFE_PHASE=proxmox_lan_sshd_reachability_read_only_diagnostics_requires_approval"; do
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

echo "PASS: production runtime remains unchanged after EG plan"
echo "PASS: Phase 14J-EG Proxmox LAN sshd reachability plan smoke passed"
