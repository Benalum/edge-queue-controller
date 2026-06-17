#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-eb-direct-proxmox-sshd-target-candidate-read-only-diagnostics"
DOC="docs/${PHASE}.md"
DB="edge_queue.sqlite3"
SERVICE="edge-queue-controller.service"

echo "=== Phase 14J-EB smoke: direct Proxmox sshd target candidate read-only diagnostics ==="

test -f "$DOC"
echo "PASS: EB doc exists"

for marker in \
  "PHASE_14J_EB_DIRECT_PROXMOX_SSHD_TARGET_CANDIDATE_READ_ONLY_DIAGNOSTICS" \
  "MUTATION_SCOPE=docs_smoke_only_direct_proxmox_sshd_target_candidate_read_only_diagnostics_result" \
  "APPROVAL_CONFIRMED=yes" \
  "EB_DIAGNOSTICS_RESULT=completed_read_only" \
  "EB_MUTATION_RESULT=none" \
  "CANDIDATE_SOURCE=one_time_local_shell_variable" \
  "CANDIDATE_PRESENT=yes" \
  "CONFIGURED_SSH_TARGET_HASH=7d65a629e9ce" \
  "CONFIGURED_SSH_HOST_HASH=9960b990ae47" \
  "CANDIDATE_TARGET_HASH=ef0e0f06f1f5" \
  "CANDIDATE_HOST_HASH=9960b990ae47" \
  "CANDIDATE_DIFFERS_FROM_CONFIGURED_TAILSCALE_ENDPOINT=no" \
  "CANDIDATE_STATUS=invalid_same_as_configured_tailscale_ssh_endpoint" \
  "EB_NARROWED_RESULT=provided_candidate_is_same_configured_tailscale_ssh_endpoint" \
  "DIRECT_PROXMOX_SSHD_CANDIDATE_VALID=no" \
  "DIRECT_PROXMOX_SSHD_CANDIDATE_FOUND=no" \
  "CANDIDATE_BANNER_PROBE_PERFORMED=no" \
  "CANDIDATE_KEYSCAN_PROBE_PERFORMED=no" \
  "CANDIDATE_REJECTED_BEFORE_NETWORK_PROBE=yes" \
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
  "NEXT_PHASE_NAME=phase-14j-ec-direct-proxmox-sshd-candidate-selection-guidance" \
  "APP_SOURCE_MUTATION=not_performed" \
  "PRODUCTION_DB_MUTATION=not_performed" \
  "JOB_MUTATION=not_performed" \
  "SERVICE_RESTART_RELOAD=not_performed" \
  "CT101_CALL=not_performed" \
  "MODEL_OLLAMA_CALL=not_performed" \
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
  "DO_NOT_RERUN_14J_AG_APPLY_WRAPPER=preserved" \
  "NO_SECRETS_PRINTED=yes" \
  "DIRECT_PROXMOX_SSHD_TARGET_CANDIDATE_READ_ONLY_DIAGNOSTICS_RESULT=completed_invalid_same_candidate" \
  "NEXT_SAFE_PHASE=direct_proxmox_sshd_candidate_selection_guidance"; do
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

echo "PASS: production runtime remains unchanged after EB checkpoint"
echo "PASS: Phase 14J-EB direct Proxmox sshd target candidate read-only diagnostics smoke passed"
