#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-dx-ssh-handshake-or-hostkey-timeout-read-only-diagnostics"
DOC="docs/${PHASE}.md"
DB="edge_queue.sqlite3"
SERVICE="edge-queue-controller.service"

echo "=== Phase 14J-DX smoke: SSH handshake/host-key timeout read-only diagnostics ==="

test -f "$DOC"
echo "PASS: DX doc exists"

for marker in \
  "PHASE_14J_DX_SSH_HANDSHAKE_OR_HOSTKEY_TIMEOUT_READ_ONLY_DIAGNOSTICS" \
  "MUTATION_SCOPE=docs_smoke_only_ssh_handshake_or_hostkey_timeout_read_only_diagnostics_result" \
  "APPROVAL_CONFIRMED=yes" \
  "DX_DIAGNOSTICS_RESULT=completed_read_only" \
  "DX_MUTATION_RESULT=none" \
  "EDGE_PROXMOX_SSH_TARGET_PRESENT=yes" \
  "EDGE_POWER_TARGET_MAP_PRESENT=yes" \
  "EDGE_POWER_TARGET_MAP_MENTIONS_LLMS_OLLAMA=yes" \
  "SSH_BANNER_RESULT=received" \
  "SSH_BANNER_PREFIX=SSH-2.0" \
  "SSH_BANNER_VENDOR_SANITIZED=Tailscale" \
  "SSH_KEYSCAN_RC=0" \
  "SSH_KEYSCAN_KEY_LINE_COUNT=3" \
  "SSH_KEYSCAN_KEY_TYPES=ecdsa-sha2-nistp256,ssh-ed25519,ssh-rsa" \
  "SSH_KEYSCAN_STRICT_TRUE_RC=255" \
  "SSH_KEYSCAN_STRICT_CONNECTION_ESTABLISHED=yes" \
  "SSH_KEYSCAN_STRICT_REMOTE_PROTOCOL_SEEN=yes" \
  "SSH_KEYSCAN_STRICT_KEXINIT_SEEN=yes" \
  "SSH_KEYSCAN_STRICT_SERVER_HOSTKEY_SEEN=yes" \
  "SSH_KEYSCAN_STRICT_HOSTKEY_VERIFICATION_FAILED=no" \
  "SSH_KEYSCAN_STRICT_AUTH_CONTINUE_SEEN=no" \
  "SSH_KEYSCAN_STRICT_OFFERING_PUBLICKEY=no" \
  "SSH_KEYSCAN_STRICT_REMOTE_COMMAND_EXECUTED=no" \
  "SSH_KEYSCAN_STRICT_TIMEOUT_SEEN=yes" \
  "SSH_KEYSCAN_STRICT_CLASSIFICATION=post_hostkey_pre_auth_timeout" \
  "SSH_ACCEPTNEW_TRUE_RC=255" \
  "SSH_ACCEPTNEW_HOSTKEY_VERIFICATION_FAILED=no" \
  "SSH_ACCEPTNEW_CLASSIFICATION=post_hostkey_pre_auth_timeout" \
  "SSH_PUBKEY_ONLY_IDENTITIESONLY_TRUE_RC=255" \
  "SSH_PUBKEY_ONLY_IDENTITIESONLY_HOSTKEY_VERIFICATION_FAILED=no" \
  "SSH_PUBKEY_ONLY_IDENTITIESONLY_CLASSIFICATION=post_hostkey_pre_auth_timeout" \
  "SSH_G_RC=0" \
  "SSH_G_IDENTITYFILE_COUNT=7" \
  "SSH_G_IDENTITYFILE_EXISTING_COUNT=1" \
  "SSH_G_IDENTITIESONLY=no" \
  "SSH_G_BATCHMODE=yes" \
  "SSH_G_PROXYJUMP_PRESENT=no" \
  "SSH_G_PROXYCOMMAND_PRESENT=no" \
  "DX_NARROWED_ROOT_CAUSE_AREA=tailscale_ssh_or_pre_auth_policy_timeout_after_hostkey" \
  "SSH_BANNER_AND_KEYSCAN_SUCCEED=yes" \
  "SSH_HOSTKEY_VERIFICATION_FAILURE=no" \
  "SSH_POST_HOSTKEY_PRE_AUTH_TIMEOUT=yes" \
  "SSH_REMOTE_COMMAND_EXECUTION_REACHED=no" \
  "GUARDED_WORKER_START_REMAINS_BLOCKED=yes" \
  "SERVICE_FLAG_REMAINED_UNSET=verified" \
  "SQLITE_QUICK_CHECK_AFTER=ok" \
  "WORKER_FACTS_UNCHANGED=verified" \
  "STUDY_ROW_REMAINED_ENABLED_OFFLINE=verified" \
  "JOB_SUMMARY_UNCHANGED=verified" \
  "PRODUCTION_STATE_UNCHANGED_AFTER_DIAGNOSTICS=verified" \
  "NEXT_PHASE_NAME=phase-14j-dy-tailscale-ssh-vs-proxmox-sshd-target-plan" \
  "APP_SOURCE_MUTATION=not_performed" \
  "PRODUCTION_DB_MUTATION=not_performed" \
  "JOB_MUTATION=not_performed" \
  "SERVICE_RESTART_RELOAD=not_performed" \
  "CT101_CALL=not_performed" \
  "MODEL_OLLAMA_CALL=not_performed" \
  "POWER_ENDPOINT_CALL=not_performed" \
  "PROXMOX_SSH_CALL_IN_CHECKPOINT=not_performed" \
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
  "SSH_HANDSHAKE_OR_HOSTKEY_TIMEOUT_READ_ONLY_DIAGNOSTICS_RESULT=completed" \
  "NEXT_SAFE_PHASE=tailscale_ssh_vs_proxmox_sshd_target_plan"; do
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

echo "PASS: production runtime remains unchanged after DX checkpoint"
echo "PASS: Phase 14J-DX SSH handshake/host-key timeout read-only diagnostics smoke passed"
