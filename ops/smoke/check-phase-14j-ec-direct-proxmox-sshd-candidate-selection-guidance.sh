#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-ec-direct-proxmox-sshd-candidate-selection-guidance"
DOC="docs/${PHASE}.md"
DB="edge_queue.sqlite3"
SERVICE="edge-queue-controller.service"

echo "=== Phase 14J-EC smoke: direct Proxmox sshd candidate selection guidance ==="

test -f "$DOC"
echo "PASS: EC doc exists"

for marker in \
  "PHASE_14J_EC_DIRECT_PROXMOX_SSHD_CANDIDATE_SELECTION_GUIDANCE" \
  "MUTATION_SCOPE=docs_smoke_only_direct_proxmox_sshd_candidate_selection_guidance" \
  "DIRECT_PROXMOX_SSHD_TARGET_CANDIDATE_READ_ONLY_DIAGNOSTICS_RESULT=completed_invalid_same_candidate" \
  "EB_NARROWED_RESULT=provided_candidate_is_same_configured_tailscale_ssh_endpoint" \
  "DIRECT_PROXMOX_SSHD_CANDIDATE_VALID=no" \
  "DIRECT_PROXMOX_SSHD_CANDIDATE_FOUND=no" \
  "CANDIDATE_REJECTED_BEFORE_NETWORK_PROBE=yes" \
  "DIRECT_PROXMOX_SSHD_CANDIDATE_SELECTION_GUIDANCE=ready" \
  "DO_NOT_PASTE_RAW_CANDIDATE_IN_CHAT=yes" \
  "SET_CANDIDATE_AS_LOCAL_SHELL_VARIABLE_ONLY=yes" \
  "CANDIDATE_MUST_DIFFER_FROM_CONFIGURED_TAILSCALE_ENDPOINT_HASH=yes" \
  "CANDIDATE_EXPECTED_BANNER_VENDOR=OpenSSH_or_other_non_Tailscale_sshd" \
  "CANDIDATE_TAILSCALE_BANNER_IS_INVALID=yes" \
  "CANDIDATE_FIRST_CHECK_ALLOWED_TCP_22_BANNER_ONLY=yes" \
  "CANDIDATE_FIRST_CHECK_ALLOWED_KEYSCAN_HASH_ONLY=yes" \
  "CANDIDATE_FIRST_CHECK_PROXMOX_REMOTE_COMMAND_EXECUTION=no" \
  "CANDIDATE_FIRST_CHECK_SERVICE_ENV_MUTATION=no" \
  "CANDIDATE_FIRST_CHECK_POWER_ENDPOINT_CALL=no" \
  "NEXT_PHASE_NAME=phase-14j-ed-direct-proxmox-sshd-target-candidate-read-only-diagnostics-retry" \
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
  "DO_NOT_RERUN_14J_AG_APPLY_WRAPPER=preserved" \
  "NO_SECRETS_PRINTED=yes" \
  "DIRECT_PROXMOX_SSHD_CANDIDATE_SELECTION_GUIDANCE_RESULT=ready_for_local_candidate_retry" \
  "NEXT_SAFE_PHASE=direct_proxmox_sshd_target_candidate_read_only_diagnostics_retry_requires_approval"; do
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

echo "PASS: production runtime remains unchanged after EC guidance"
echo "PASS: Phase 14J-EC direct Proxmox sshd candidate selection guidance smoke passed"
