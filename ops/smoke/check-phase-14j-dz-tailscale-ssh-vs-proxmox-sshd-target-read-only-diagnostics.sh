#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-dz-tailscale-ssh-vs-proxmox-sshd-target-read-only-diagnostics"
DOC="docs/${PHASE}.md"
DB="edge_queue.sqlite3"
SERVICE="edge-queue-controller.service"

echo "=== Phase 14J-DZ smoke: Tailscale SSH vs Proxmox sshd target read-only diagnostics ==="

test -f "$DOC"
echo "PASS: DZ doc exists"

for marker in \
  "PHASE_14J_DZ_TAILSCALE_SSH_VS_PROXMOX_SSHD_TARGET_READ_ONLY_DIAGNOSTICS" \
  "MUTATION_SCOPE=docs_smoke_only_tailscale_ssh_vs_proxmox_sshd_target_read_only_diagnostics_result" \
  "APPROVAL_CONFIRMED=yes" \
  "DZ_DIAGNOSTICS_RESULT=completed_read_only" \
  "DZ_MUTATION_RESULT=none" \
  "EDGE_PROXMOX_SSH_TARGET_PRESENT=yes" \
  "EDGE_PROXMOX_HOST_PRESENT=yes" \
  "EDGE_POWER_TARGET_MAP_PRESENT=yes" \
  "EDGE_POWER_TARGET_MAP_MENTIONS_LLMS_OLLAMA=yes" \
  "TAILSCALE_STATUS_RC=0" \
  "TAILSCALE_BACKEND_STATE=Running" \
  "TAILSCALE_PEER_COUNT=3" \
  "CONFIGURED_SSH_HOST_TAILSCALE_PEER_MATCH=yes" \
  "CONFIGURED_SSH_HOST_TAILSCALE_PEER_ONLINE=true" \
  "EDGE_PROXMOX_HOST_TAILSCALE_PEER_MATCH=yes" \
  "EDGE_PROXMOX_HOST_TAILSCALE_PEER_ONLINE=true" \
  "CONFIGURED_SSH_HOST_EQUALS_EDGE_PROXMOX_HOST=yes" \
  "CONFIGURED_SSH_HOST_PRESENT=yes" \
  "CONFIGURED_SSH_HOST_TCP22_RESULT=received" \
  "CONFIGURED_SSH_HOST_BANNER_PREFIX=SSH-2.0" \
  "CONFIGURED_SSH_HOST_BANNER_VENDOR=Tailscale" \
  "CONFIGURED_SSH_HOST_KEYSCAN_RC=0" \
  "CONFIGURED_SSH_HOST_KEYSCAN_KEY_LINE_COUNT=3" \
  "CONFIGURED_SSH_HOST_KEYSCAN_KEY_TYPES=ecdsa-sha2-nistp256,ssh-ed25519,ssh-rsa" \
  "EDGE_PROXMOX_HOST_PRESENT=yes_same_as_configured_ssh_host" \
  "EDGE_PROXMOX_HOST_TCP22_RESULT=skipped_same_or_missing" \
  "EDGE_PROXMOX_HOST_KEYSCAN_RC=skipped_same_or_missing" \
  "TARGET_DECISION_INPUTS_RECORDED=yes" \
  "TARGET_DECISION_DEFAULT_RECOMMENDATION=prefer_direct_proxmox_sshd_for_noninteractive_controller_automation_if_available" \
  "TARGET_DECISION_TAILSCALE_SSH_ENDPOINT_BATCHMODE_STATUS=not_suitable_based_on_dx_pre_auth_timeout" \
  "TARGET_DECISION_NEXT_ACTION=checkpoint_results_and_plan_target_fix_or_direct_sshd_candidate" \
  "DZ_NARROWED_ROOT_CAUSE_AREA=configured_target_is_tailscale_ssh_endpoint_no_direct_proxmox_sshd_candidate_present" \
  "CONFIGURED_TARGET_VENDOR=Tailscale" \
  "EDGE_PROXMOX_HOST_SAME_AS_CONFIGURED_SSH_HOST=yes" \
  "DIRECT_PROXMOX_SSHD_CANDIDATE_PRESENT=no" \
  "TAILSCALE_SSH_BATCHMODE_NOT_SUITABLE_FOR_CONTROLLER_AUTOMATION=yes" \
  "PREFERRED_TARGET_FOR_NONINTERACTIVE_CONTROLLER_AUTOMATION=direct_proxmox_sshd_if_available" \
  "GUARDED_WORKER_START_REMAINS_BLOCKED=yes" \
  "SERVICE_FLAG_REMAINED_UNSET=verified" \
  "SQLITE_QUICK_CHECK_AFTER=ok" \
  "WORKER_FACTS_UNCHANGED=verified" \
  "STUDY_ROW_REMAINED_ENABLED_OFFLINE=verified" \
  "JOB_SUMMARY_UNCHANGED=verified" \
  "PRODUCTION_STATE_UNCHANGED_AFTER_DIAGNOSTICS=verified" \
  "NEXT_PHASE_NAME=phase-14j-ea-direct-proxmox-sshd-target-candidate-plan" \
  "APP_SOURCE_MUTATION=not_performed" \
  "PRODUCTION_DB_MUTATION=not_performed" \
  "JOB_MUTATION=not_performed" \
  "SERVICE_RESTART_RELOAD=not_performed" \
  "CT101_CALL=not_performed" \
  "MODEL_OLLAMA_CALL=not_performed" \
  "POWER_ENDPOINT_CALL=not_performed" \
  "PROXMOX_SSH_CALL_IN_CHECKPOINT=not_performed" \
  "PROXMOX_REMOTE_COMMAND_EXECUTION=not_performed" \
  "WORKER_START_PERFORMED=no" \
  "SCHEDULER_LANE_DISPATCH_ACTIVATION=not_performed" \
  "PRIMARY_WORKER_FILTERING_ACTIVATION=not_performed" \
  "PERSISTENT_LANE_WORKER_STARTUP=not_performed" \
  "RUNTIME_ACTIVATION=not_performed" \
  "GITHUB_BRANCH_OR_REPO_DELETE=not_performed" \
  "FULL_SYSTEMD_ENVIRONMENT_PRINTING=not_performed" \
  "RAW_SSH_TARGET_PRINTING=not_performed" \
  "RAW_KEY_PATH_PRINTING=not_performed" \
  "HASH_ONLY_HOSTKEY_OUTPUT=yes" \
  "DO_NOT_RERUN_14J_AG_APPLY_WRAPPER=preserved" \
  "NO_SECRETS_PRINTED=yes" \
  "TAILSCALE_SSH_VS_PROXMOX_SSHD_TARGET_READ_ONLY_DIAGNOSTICS_RESULT=completed" \
  "NEXT_SAFE_PHASE=direct_proxmox_sshd_target_candidate_plan"; do
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

echo "PASS: production runtime remains unchanged after DZ checkpoint"
echo "PASS: Phase 14J-DZ Tailscale SSH vs Proxmox sshd target read-only diagnostics smoke passed"
