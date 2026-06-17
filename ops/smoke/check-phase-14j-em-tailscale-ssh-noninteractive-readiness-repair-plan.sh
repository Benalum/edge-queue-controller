#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-em-tailscale-ssh-noninteractive-readiness-repair-plan"
DOC="docs/${PHASE}.md"
DB="edge_queue.sqlite3"
SERVICE="edge-queue-controller.service"

echo "=== Phase 14J-EM smoke: Tailscale SSH noninteractive readiness repair plan ==="

test -f "$DOC"
echo "PASS: EM doc exists"

for marker in \
  "PHASE_14J_EM_TAILSCALE_SSH_NONINTERACTIVE_READINESS_REPAIR_PLAN" \
  "MUTATION_SCOPE=docs_smoke_only_tailscale_ssh_noninteractive_readiness_repair_plan" \
  "SAFE_TRAP_PATTERN=yes" \
  "NO_TRAP_EXIT=yes" \
  "EL_RESULT=completed_tailscale_target_reachable_but_noninteractive_ssh_failed" \
  "CONFIGURED_TAILSCALE_TARGET_NETWORK_REACHABLE=yes" \
  "CONFIGURED_TAILSCALE_TARGET_BANNER_VENDOR=Tailscale" \
  "CONFIGURED_PROXMOX_READ_ONLY_SSH_RC=255" \
  "CONFIGURED_TAILSCALE_REMOTE_AUTH_OR_COMMAND_READY=no" \
  "DIRECT_LAN_SSHD_REQUIRED=no" \
  "LAN_FIREWALL_TCP22_OPEN_REQUIRED=no" \
  "GUARDED_WORKER_START_REMAINS_BLOCKED=yes" \
  "TAILSCALE_SSH_NONINTERACTIVE_READINESS_REPAIR_PLAN=ready" \
  "TAILSCALE_SSH_ACL_OR_USER_MAPPING_ISSUE=possible" \
  "CONFIGURED_SSH_TARGET_USER_MISMATCH=possible" \
  "TAILSCALE_SSH_NONINTERACTIVE_COMMAND_POLICY_ISSUE=possible" \
  "SSH_TARGET_FORMATTING_OR_OPTIONS_ISSUE=possible" \
  "AUTH_REQUIRES_INTERACTIVE_TAILSCALE_FLOW=possible" \
  "TARGET_REACHABLE_BUT_COMMAND_EXECUTION_BLOCKED=confirmed_context" \
  "CHECK_CONFIGURED_PROXMOX_SSH_TARGET_PRESENT_HASH_ONLY=yes" \
  "CHECK_CONFIGURED_TARGET_TCP22_BANNER_HASH_ONLY=yes" \
  "CHECK_SSH_BATCHMODE_FAILURE_REASON_SANITIZED=yes" \
  "CHECK_SSH_VERBOSE_AUTH_STAGE_SANITIZED_LIMITED=yes" \
  "CHECK_SSH_EXIT_CODE_ONLY=yes" \
  "CHECK_NO_REMOTE_MUTATION=yes" \
  "TAILSCALE_ACL_MUTATION=not_allowed" \
  "TAILSCALE_ADMIN_CONSOLE_CHANGE=not_allowed" \
  "PROXMOX_USER_MUTATION=not_allowed" \
  "SSH_CONFIG_MUTATION=not_allowed" \
  "FIREWALL_MUTATION=not_allowed" \
  "LAN_FIREWALL_TCP22_OPEN=not_allowed" \
  "REQUIRE_SAFE_SUBSHELL_TRAP_PATTERN=yes" \
  "REQUIRE_NO_EXIT_IN_TRAP=yes" \
  "NEXT_PHASE_NAME=phase-14j-en-tailscale-ssh-noninteractive-readiness-read-only-diagnostics" \
  "APP_SOURCE_MUTATION=not_performed" \
  "PRODUCTION_DB_MUTATION=not_performed" \
  "JOB_MUTATION=not_performed" \
  "CONTROLLER_SERVICE_RESTART_RELOAD=not_performed" \
  "PROXMOX_SERVICE_RESTART_RELOAD=not_performed" \
  "POWER_ENDPOINT_CALL=not_performed" \
  "WORKER_START_PERFORMED=no" \
  "RUNTIME_ACTIVATION=not_performed" \
  "SERVICE_ENV_MUTATION=not_performed" \
  "PROXMOX_SSH_CALL=not_performed" \
  "PROXMOX_REMOTE_COMMAND_EXECUTION=not_performed" \
  "GITHUB_BRANCH_OR_REPO_DELETE=not_performed" \
  "FULL_SYSTEMD_ENVIRONMENT_PRINTING=not_performed" \
  "RAW_SSH_TARGET_PRINTING=not_performed" \
  "RAW_KEY_PATH_PRINTING=not_performed" \
  "HASH_ONLY_CONFIGURED_TARGET_OUTPUT=yes" \
  "DO_NOT_RERUN_14J_AG_APPLY_WRAPPER=preserved" \
  "NO_SECRETS_PRINTED=yes" \
  "TAILSCALE_SSH_NONINTERACTIVE_READINESS_REPAIR_PLAN_RESULT=ready_for_read_only_diagnostics" \
  "NEXT_SAFE_PHASE=tailscale_ssh_noninteractive_readiness_read_only_diagnostics_requires_approval"; do
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

echo "PASS: production runtime remains unchanged after EM plan"
echo "PASS: Phase 14J-EM Tailscale SSH noninteractive readiness repair plan smoke passed"
