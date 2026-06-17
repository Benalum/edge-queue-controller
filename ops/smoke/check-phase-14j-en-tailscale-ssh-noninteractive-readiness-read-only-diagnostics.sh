#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-en-tailscale-ssh-noninteractive-readiness-read-only-diagnostics"
DOC="docs/${PHASE}.md"
DB="edge_queue.sqlite3"
SERVICE="edge-queue-controller.service"

echo "=== Phase 14J-EN smoke: Tailscale SSH noninteractive readiness read-only diagnostics ==="

test -f "$DOC"
echo "PASS: EN doc exists"

for marker in \
  "PHASE_14J_EN_TAILSCALE_SSH_NONINTERACTIVE_READINESS_READ_ONLY_DIAGNOSTICS" \
  "MUTATION_SCOPE=docs_smoke_only_tailscale_ssh_noninteractive_readiness_result" \
  "SAFE_TRAP_PATTERN=yes" \
  "NO_TRAP_EXIT=yes" \
  "EN_DIAGNOSTICS_RESULT=completed_read_only" \
  "EN_MUTATION_RESULT=none" \
  "CONFIGURED_PROXMOX_SSH_TARGET_PRESENT=yes" \
  "CONFIGURED_PROXMOX_SSH_TARGET_HASH=7d65a629e9ce" \
  "CONFIGURED_PROXMOX_SSH_HOST_HASH=9960b990ae47" \
  "CONFIGURED_PROXMOX_SSH_USER_HASH=4813494d137e" \
  "CONFIGURED_PROXMOX_SSH_USER_PRESENT=yes" \
  "CONFIGURED_TARGET_TCP22_RESULT=received" \
  "CONFIGURED_TARGET_BANNER_PREFIX=SSH-2.0" \
  "CONFIGURED_TARGET_BANNER_VENDOR=Tailscale" \
  "SSH_G_RC=0" \
  "SSH_BATCHMODE_RC=255" \
  "SSH_BATCHMODE_REMOTE_MARKER_SEEN=no" \
  "SSH_VERBOSE_RC=255" \
  "SSH_VERBOSE_REMOTE_MARKER_SEEN=no" \
  "SSH_VERBOSE_AUTH_TAILSCALE_SEEN=yes" \
  "SSH_VERBOSE_AUTH_AUTHENTICATING_SEEN=yes" \
  "SSH_VERBOSE_AUTH_STAGE_REQUIRED_TAILSCALE_ADDITIONAL_CHECK=yes" \
  "SSH_VERBOSE_AUTH_STAGE_RAW_URL_RECORDED=no" \
  "TAILSCALE_SSH_NONINTERACTIVE_READINESS_STATUS=tailscale_ssh_noninteractive_tailscale_auth_or_acl_issue" \
  "EN_NARROWED_RESULT=tailscale_ssh_requires_additional_auth_check_for_noninteractive_command" \
  "CONFIGURED_TAILSCALE_TARGET_NETWORK_REACHABLE=yes" \
  "SSH_CONFIG_EXPANSION_WORKS=yes" \
  "NONINTERACTIVE_SSH_READY=no" \
  "REMOTE_COMMAND_EXECUTED=no" \
  "TAILSCALE_AUTH_OR_ACL_ISSUE_CONFIRMED=yes" \
  "TAILSCALE_ADDITIONAL_CHECK_REQUIRED=yes" \
  "DIRECT_LAN_SSHD_REQUIRED=no" \
  "LAN_FIREWALL_TCP22_OPEN_REQUIRED=no" \
  "GUARDED_WORKER_START_REMAINS_BLOCKED=yes" \
  "PRODUCTION_STATE_UNCHANGED_AFTER_DIAGNOSTICS=verified" \
  "NEXT_PHASE_NAME=phase-14j-eo-tailscale-ssh-auth-policy-repair-plan" \
  "TAILSCALE_ACL_MUTATION=not_performed" \
  "TAILSCALE_ADMIN_CONSOLE_CHANGE=not_performed" \
  "PROXMOX_USER_MUTATION=not_performed" \
  "RAW_TAILSCALE_AUTH_URL_RECORDING=not_performed" \
  "HASH_ONLY_CONFIGURED_TARGET_OUTPUT=yes" \
  "DO_NOT_RERUN_14J_AG_APPLY_WRAPPER=preserved" \
  "NO_SECRETS_PRINTED=yes" \
  "TAILSCALE_SSH_NONINTERACTIVE_READINESS_READ_ONLY_DIAGNOSTICS_RESULT=completed_tailscale_auth_or_acl_additional_check_required" \
  "NEXT_SAFE_PHASE=tailscale_ssh_auth_policy_repair_plan"; do
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

echo "PASS: production runtime remains unchanged after EN checkpoint"
echo "PASS: Phase 14J-EN Tailscale SSH noninteractive readiness diagnostics smoke passed"
