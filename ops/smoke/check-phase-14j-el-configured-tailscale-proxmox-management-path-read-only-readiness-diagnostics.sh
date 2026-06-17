#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-el-configured-tailscale-proxmox-management-path-read-only-readiness-diagnostics"
DOC="docs/${PHASE}.md"
DB="edge_queue.sqlite3"
SERVICE="edge-queue-controller.service"

echo "=== Phase 14J-EL smoke: configured Tailscale Proxmox management path read-only readiness diagnostics ==="

test -f "$DOC"
echo "PASS: EL doc exists"

for marker in \
  "PHASE_14J_EL_CONFIGURED_TAILSCALE_PROXMOX_MANAGEMENT_PATH_READ_ONLY_READINESS_DIAGNOSTICS" \
  "MUTATION_SCOPE=docs_smoke_only_configured_tailscale_proxmox_management_path_readiness_result" \
  "EL_DIAGNOSTICS_RESULT=completed_read_only" \
  "EL_MUTATION_RESULT=none" \
  "CONFIGURED_PROXMOX_SSH_TARGET_PRESENT=yes" \
  "CONFIGURED_PROXMOX_SSH_TARGET_HASH=7d65a629e9ce" \
  "CONFIGURED_PROXMOX_SSH_HOST_HASH=9960b990ae47" \
  "CONFIGURED_PROXMOX_SSH_TARGET_RAW_PRINTED=no" \
  "CONFIGURED_PROXMOX_KEY_PATH_RAW_PRINTED=no" \
  "CONFIGURED_TARGET_TCP22_RESULT=received" \
  "CONFIGURED_TARGET_BANNER_PREFIX=SSH-2.0" \
  "CONFIGURED_TARGET_BANNER_VENDOR=Tailscale" \
  "CONFIGURED_TARGET_BANNER_HASH=e687598eb9c872c4" \
  "CONFIGURED_PROXMOX_READ_ONLY_SSH_RC=255" \
  "CONFIGURED_PROXMOX_READ_ONLY_STDERR_EMPTY=yes" \
  "CONFIGURED_PROXMOX_READ_ONLY_STDOUT_EMPTY=yes" \
  "REMOTE_READ_ONLY_CHECKS_STARTED_OBSERVED=unknown" \
  "REMOTE_READ_ONLY_CHECKS_COMPLETE_OBSERVED=unknown" \
  "REMOTE_MUTATION_RESULT_OBSERVED=unknown" \
  "CONFIGURED_TAILSCALE_PROXMOX_MANAGEMENT_PATH_READINESS_STATUS=configured_tailscale_target_tcp22_reachable_but_read_only_ssh_failed" \
  "CONFIGURED_TAILSCALE_PROXMOX_READ_ONLY_CHECKS_EXECUTED=yes" \
  "CONFIGURED_TAILSCALE_PROXMOX_MUTATION_RESULT=none" \
  "LOCAL_MUTATION_RESULT=none" \
  "EL_NARROWED_RESULT=tailscale_target_reachable_but_noninteractive_ssh_failed" \
  "CONFIGURED_TAILSCALE_TARGET_NETWORK_REACHABLE=yes" \
  "CONFIGURED_TAILSCALE_TARGET_BANNER_VENDOR=Tailscale" \
  "CONFIGURED_TAILSCALE_REMOTE_READ_ONLY_COMMAND_EXECUTED=no" \
  "CONFIGURED_TAILSCALE_REMOTE_AUTH_OR_COMMAND_READY=no" \
  "DIRECT_LAN_SSHD_REQUIRED=no" \
  "LAN_FIREWALL_TCP22_OPEN_REQUIRED=no" \
  "GUARDED_WORKER_START_REMAINS_BLOCKED=yes" \
  "SERVICE_FLAG_REMAINED_UNSET=verified" \
  "SQLITE_QUICK_CHECK_AFTER=ok" \
  "WORKER_FACTS_UNCHANGED=verified" \
  "STUDY_ROW_REMAINED_ENABLED_OFFLINE=verified" \
  "JOB_SUMMARY_UNCHANGED=verified" \
  "PRODUCTION_STATE_UNCHANGED_AFTER_DIAGNOSTICS=verified" \
  "NEXT_PHASE_NAME=phase-14j-em-tailscale-ssh-noninteractive-readiness-repair-plan" \
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
  "PROXMOX_SERVICE_MUTATION=not_performed" \
  "GITHUB_BRANCH_OR_REPO_DELETE=not_performed" \
  "FULL_SYSTEMD_ENVIRONMENT_PRINTING=not_performed" \
  "RAW_SSH_TARGET_PRINTING=not_performed" \
  "RAW_KEY_PATH_PRINTING=not_performed" \
  "HASH_ONLY_CONFIGURED_TARGET_OUTPUT=yes" \
  "DO_NOT_RERUN_14J_AG_APPLY_WRAPPER=preserved" \
  "NO_SECRETS_PRINTED=yes" \
  "CONFIGURED_TAILSCALE_PROXMOX_MANAGEMENT_PATH_READ_ONLY_READINESS_DIAGNOSTICS_RESULT=completed_tailscale_target_reachable_but_noninteractive_ssh_failed" \
  "NEXT_SAFE_PHASE=tailscale_ssh_noninteractive_readiness_repair_plan"; do
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

echo "PASS: production runtime remains unchanged after EL checkpoint"
echo "PASS: Phase 14J-EL configured Tailscale Proxmox readiness diagnostics smoke passed"
