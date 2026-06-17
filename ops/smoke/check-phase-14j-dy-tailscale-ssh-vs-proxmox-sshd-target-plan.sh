#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-dy-tailscale-ssh-vs-proxmox-sshd-target-plan"
DOC="docs/${PHASE}.md"
DB="edge_queue.sqlite3"
SERVICE="edge-queue-controller.service"

echo "=== Phase 14J-DY smoke: Tailscale SSH vs Proxmox sshd target plan ==="

test -f "$DOC"
echo "PASS: DY doc exists"

for marker in \
  "PHASE_14J_DY_TAILSCALE_SSH_VS_PROXMOX_SSHD_TARGET_PLAN" \
  "MUTATION_SCOPE=docs_smoke_only_tailscale_ssh_vs_proxmox_sshd_target_plan" \
  "SSH_HANDSHAKE_OR_HOSTKEY_TIMEOUT_READ_ONLY_DIAGNOSTICS_RESULT=completed" \
  "DX_NARROWED_ROOT_CAUSE_AREA=tailscale_ssh_or_pre_auth_policy_timeout_after_hostkey" \
  "SSH_BANNER_PREFIX=SSH-2.0" \
  "SSH_BANNER_VENDOR_SANITIZED=Tailscale" \
  "SSH_KEYSCAN_RC=0" \
  "SSH_HOSTKEY_VERIFICATION_FAILURE=no" \
  "SSH_POST_HOSTKEY_PRE_AUTH_TIMEOUT=yes" \
  "SSH_REMOTE_COMMAND_EXECUTION_REACHED=no" \
  "TAILSCALE_SSH_VS_PROXMOX_SSHD_TARGET_PLAN=ready_for_read_only_target_decision_diagnostics" \
  "CHECK_TAILSCALE_SSH_STATUS_REDACTED=yes" \
  "CHECK_DIRECT_PROXMOX_SSHD_CANDIDATE_TARGETS_REDACTED=yes" \
  "CHECK_TCP_22_BANNER_VENDOR_FOR_CANDIDATES=yes" \
  "CHECK_SSH_KEYSCAN_HASH_ONLY_FOR_CANDIDATES=yes" \
  "CHECK_NO_RAW_SSH_TARGET_OR_KEY_PATH_OUTPUT=yes" \
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
  "ALLOW_RAW_SECRET_OR_TARGET_OUTPUT=no" \
  "REQUIRE_SANITIZED_OUTPUT=yes" \
  "REQUIRE_NO_SECRET_PRINTING=yes" \
  "REQUIRE_SHORT_TIMEOUTS=yes" \
  "REQUIRE_NO_FULL_SYSTEMD_ENVIRONMENT_PRINT=yes" \
  "REQUIRE_NO_RAW_SSH_TARGET_PRINTING=yes" \
  "REQUIRE_NO_RAW_KEY_PATH_PRINTING=yes" \
  "REQUIRE_HASH_ONLY_HOSTKEY_OUTPUT=yes" \
  "GUARDED_WORKER_START_REMAINS_BLOCKED=yes" \
  "TAILSCALE_SSH_VS_PROXMOX_SSHD_TARGET_DECISION_REQUIRED=yes" \
  "NEXT_PHASE_NAME=phase-14j-dz-tailscale-ssh-vs-proxmox-sshd-target-read-only-diagnostics" \
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
  "GITHUB_BRANCH_OR_REPO_DELETE=not_performed" \
  "FULL_SYSTEMD_ENVIRONMENT_PRINTING=not_performed" \
  "RAW_SSH_TARGET_PRINTING=not_performed" \
  "RAW_KEY_PATH_PRINTING=not_performed" \
  "DO_NOT_RERUN_14J_AG_APPLY_WRAPPER=preserved" \
  "NO_SECRETS_PRINTED=yes" \
  "TAILSCALE_SSH_VS_PROXMOX_SSHD_TARGET_PLAN_RESULT=ready_for_explicit_read_only_diagnostics" \
  "NEXT_SAFE_PHASE=tailscale_ssh_vs_proxmox_sshd_target_read_only_diagnostics_requires_approval"; do
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

echo "PASS: production runtime remains unchanged after DY plan"
echo "PASS: Phase 14J-DY Tailscale SSH vs Proxmox sshd target plan smoke passed"
