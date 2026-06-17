#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-dv-ssh-rc-255-read-only-diagnostics"
DOC="docs/${PHASE}.md"
DB="edge_queue.sqlite3"
SERVICE="edge-queue-controller.service"

echo "=== Phase 14J-DV smoke: SSH rc 255 read-only diagnostics ==="

test -f "$DOC"
echo "PASS: DV doc exists"

for marker in \
  "PHASE_14J_DV_SSH_RC_255_READ_ONLY_DIAGNOSTICS" \
  "MUTATION_SCOPE=docs_smoke_only_ssh_rc_255_read_only_diagnostics_result" \
  "APPROVAL_CONFIRMED=yes" \
  "DV_DIAGNOSTICS_RESULT=completed_read_only" \
  "DV_MUTATION_RESULT=none" \
  "EDGE_PROXMOX_SSH_TARGET_PRESENT=yes" \
  "EDGE_POWER_TARGET_MAP_PRESENT=yes" \
  "EDGE_POWER_TARGET_MAP_MENTIONS_LLMS_OLLAMA=yes" \
  "SSH_HOST_RESOLUTION_RC=0" \
  "SSH_HOST_RESOLUTION_RESULT=resolved" \
  "TAILSCALE_STATUS_RC=0" \
  "TAILSCALE_BACKEND_STATE=Running" \
  "TAILSCALE_PEER_COUNT=3" \
  "TAILSCALE_PEER_MATCH=yes" \
  "TAILSCALE_PEER_ONLINE=true" \
  "TCP_22_RESULT=open" \
  "TCP_22_RC=0" \
  "SSH_VERBOSE_TRUE_RC=255" \
  "SSH_VERBOSE_TRUE_STDOUT_SIZE=0" \
  "SSH_VERBOSE_ERROR_CLASSIFICATIONS=timeout,host_key" \
  "SSH_ACCEPTNEW_TRUE_RC=255" \
  "SSH_ACCEPTNEW_TRUE_STDOUT_SIZE=0" \
  "SSH_ACCEPTNEW_ERROR_CLASSIFICATIONS=timeout,host_key" \
  "SSH_G_RC=0" \
  "SSH_G_USER_PRESENT=yes" \
  "SSH_G_HOSTNAME_PRESENT=yes" \
  "SSH_G_IDENTITYFILE_COUNT=7" \
  "SSH_G_IDENTITYFILE_EXISTING_COUNT=1" \
  "SSH_G_PROXYJUMP_PRESENT=no" \
  "SSH_G_PROXYCOMMAND_PRESENT=no" \
  "DV_NARROWED_ROOT_CAUSE_AREA=ssh_handshake_or_host_key_or_auth_timeout_after_tcp_connect" \
  "TCP_22_REACHABLE_BUT_SSH_TRUE_FAILS=yes" \
  "TAILSCALE_PEER_ONLINE_BUT_SSH_TRUE_FAILS=yes" \
  "SSH_IDENTITY_AVAILABLE_BUT_TRUE_FAILS=yes" \
  "GUARDED_WORKER_START_REMAINS_BLOCKED=yes" \
  "SERVICE_FLAG_REMAINED_UNSET=verified" \
  "SQLITE_QUICK_CHECK_AFTER=ok" \
  "WORKER_FACTS_UNCHANGED=verified" \
  "STUDY_ROW_REMAINED_ENABLED_OFFLINE=verified" \
  "JOB_SUMMARY_UNCHANGED=verified" \
  "PRODUCTION_STATE_UNCHANGED_AFTER_DIAGNOSTICS=verified" \
  "NEXT_PHASE_NAME=phase-14j-dw-ssh-handshake-or-hostkey-timeout-diagnostics-plan" \
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
  "RAW_SSH_TARGET_PRINTING=not_performed" \
  "RAW_KEY_PATH_PRINTING=not_performed" \
  "DO_NOT_RERUN_14J_AG_APPLY_WRAPPER=preserved" \
  "NO_SECRETS_PRINTED=yes" \
  "SSH_RC_255_READ_ONLY_DIAGNOSTICS_RESULT=completed" \
  "NEXT_SAFE_PHASE=ssh_handshake_or_hostkey_timeout_diagnostics_plan"; do
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

echo "PASS: production runtime remains unchanged after DV checkpoint"
echo "PASS: Phase 14J-DV SSH rc 255 read-only diagnostics smoke passed"
