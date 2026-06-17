#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-eh-proxmox-lan-sshd-reachability-read-only-diagnostics"
DOC="docs/${PHASE}.md"
DB="edge_queue.sqlite3"
SERVICE="edge-queue-controller.service"

echo "=== Phase 14J-EH smoke: Proxmox LAN sshd reachability read-only diagnostics ==="

test -f "$DOC"
echo "PASS: EH doc exists"

for marker in \
  "PHASE_14J_EH_PROXMOX_LAN_SSHD_REACHABILITY_READ_ONLY_DIAGNOSTICS" \
  "MUTATION_SCOPE=docs_smoke_only_proxmox_lan_sshd_reachability_result" \
  "APPROVAL_CONFIRMED=yes" \
  "EH_DIAGNOSTICS_RESULT=completed_read_only" \
  "EH_MUTATION_RESULT=none" \
  "CANDIDATE_SOURCE=one_time_local_shell_variable" \
  "CANDIDATE_PRESENT=yes" \
  "CONFIGURED_SSH_TARGET_HASH=7d65a629e9ce" \
  "CONFIGURED_SSH_HOST_HASH=9960b990ae47" \
  "CANDIDATE_TARGET_HASH=1544b40472dc" \
  "CANDIDATE_HOST_HASH=1544b40472dc" \
  "CANDIDATE_DIFFERS_FROM_CONFIGURED_TAILSCALE_ENDPOINT=yes" \
  "ROUTE_TO_CANDIDATE_RC=0" \
  "ROUTE_TO_CANDIDATE_PRESENT_OBSERVED=yes" \
  "ROUTE_TO_CANDIDATE_HASH=5eb1ad5ce0b743da" \
  "WIREGUARD_HOME_LINK_PRESENT=yes" \
  "WIREGUARD_HOME_OPERSTATE=unknown" \
  "WIREGUARD_HOME_WG_SHOW_AVAILABLE=no" \
  "TAILSCALE_COMMAND_PRESENT=yes" \
  "TAILSCALE_STATUS_SELF_RC=0" \
  "CANDIDATE_TCP22_RESULT=connect_timeout" \
  "CANDIDATE_BANNER_PREFIX=not_ssh_or_absent" \
  "CANDIDATE_BANNER_VENDOR=none" \
  "CANDIDATE_KEYSCAN_RC=1" \
  "CANDIDATE_KEYSCAN_KEY_LINE_COUNT=0" \
  "PROXMOX_LAN_SSHD_REACHABILITY_STATUS=local_route_exists_but_tcp22_timeout" \
  "EH_NARROWED_RESULT=local_route_exists_but_tcp22_timeout" \
  "DIRECT_PROXMOX_SSHD_CANDIDATE_VALID=no" \
  "DIRECT_PROXMOX_SSHD_CANDIDATE_FOUND=no" \
  "DIRECT_PROXMOX_SSHD_CANDIDATE_DIFFERENT_FROM_TAILSCALE_ENDPOINT=yes" \
  "LOCAL_ROUTE_TO_CANDIDATE_PRESENT=yes" \
  "WIREGUARD_HOME_LINK_PRESENT_OBSERVED=yes" \
  "TCP22_TIMEOUT_CONFIRMED=yes" \
  "CANDIDATE_BANNER_PROBE_PERFORMED=yes" \
  "CANDIDATE_KEYSCAN_PROBE_PERFORMED=yes" \
  "CANDIDATE_REJECTED_AFTER_NETWORK_PROBE=yes" \
  "PROXMOX_REMOTE_COMMAND_EXECUTION=not_performed" \
  "SERVICE_ENV_MUTATION=not_performed" \
  "POWER_ENDPOINT_CALL=not_performed" \
  "GUARDED_WORKER_START_REMAINS_BLOCKED=yes" \
  "SERVICE_FLAG_REMAINED_UNSET=verified" \
  "SQLITE_QUICK_CHECK_AFTER=ok" \
  "WORKER_FACTS_UNCHANGED=verified" \
  "STUDY_ROW_REMAINED_ENABLED_OFFLINE=verified" \
  "JOB_SUMMARY_UNCHANGED=verified" \
  "PRODUCTION_STATE_UNCHANGED_AFTER_DIAGNOSTICS=verified" \
  "NEXT_PHASE_NAME=phase-14j-ei-proxmox-sshd-timeout-investigation-plan" \
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
  "PROXMOX_REMOTE_COMMAND_EXECUTION=not_performed" \
  "GITHUB_BRANCH_OR_REPO_DELETE=not_performed" \
  "FULL_SYSTEMD_ENVIRONMENT_PRINTING=not_performed" \
  "RAW_SSH_TARGET_PRINTING=not_performed" \
  "RAW_KEY_PATH_PRINTING=not_performed" \
  "HASH_ONLY_TARGET_COMPARISON=yes" \
  "HASH_ONLY_HOSTKEY_OUTPUT=yes" \
  "SANITIZED_LOCAL_ROUTE_INTERFACE_VPN_STATUS=yes" \
  "DO_NOT_RERUN_14J_AG_APPLY_WRAPPER=preserved" \
  "NO_SECRETS_PRINTED=yes" \
  "PROXMOX_LAN_SSHD_REACHABILITY_READ_ONLY_DIAGNOSTICS_RESULT=completed_local_route_exists_but_tcp22_timeout" \
  "NEXT_SAFE_PHASE=proxmox_sshd_timeout_investigation_plan"; do
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

echo "PASS: production runtime remains unchanged after EH checkpoint"
echo "PASS: Phase 14J-EH Proxmox LAN sshd reachability diagnostics smoke passed"
