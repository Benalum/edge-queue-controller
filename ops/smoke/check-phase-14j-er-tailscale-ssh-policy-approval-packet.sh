#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-er-tailscale-ssh-policy-approval-packet"
DOC="docs/${PHASE}.md"
DB="edge_queue.sqlite3"
SERVICE="edge-queue-controller.service"

echo "=== Phase 14J-ER smoke: Tailscale SSH policy approval packet ==="

test -f "$DOC"
echo "PASS: ER doc exists"

for marker in \
  "PHASE_14J_ER_TAILSCALE_SSH_POLICY_APPROVAL_PACKET" \
  "MUTATION_SCOPE=docs_smoke_only_tailscale_ssh_policy_approval_packet" \
  "SAFE_TRAP_PATTERN=yes" \
  "NO_TRAP_EXIT=yes" \
  "EQ_RESULT=ready_for_candidate_c_approval_packet" \
  "EQ_SELECTED_PATH=dedicated_tagged_automation_identity_candidate_c" \
  "EQ_FALLBACK_PATH=narrow_tailscale_ssh_accept_rule_candidate_b" \
  "NONINTERACTIVE_SSH_READY=no" \
  "TAILSCALE_ADDITIONAL_CHECK_REQUIRED=yes" \
  "DIRECT_LAN_SSHD_REQUIRED=no" \
  "LAN_FIREWALL_TCP22_OPEN_REQUIRED=no" \
  "GUARDED_WORKER_START_REMAINS_BLOCKED=yes" \
  "TAILSCALE_SSH_POLICY_APPROVAL_PACKET=ready" \
  "APPROVAL_PACKET_TARGET_CANDIDATE=Candidate_C_dedicated_tagged_automation_identity" \
  "APPROVAL_PACKET_DOES_NOT_APPLY_POLICY=yes" \
  "APPROVAL_PACKET_PLACEHOLDER_ONLY=yes" \
  "APPROVAL_PACKET_NO_RAW_DEVICE_NAMES=yes" \
  "POLICY_SHAPE_PLACEHOLDER_ONLY=yes" \
  "POLICY_SHAPE_TAGOWNERS_REQUIRED=yes" \
  "POLICY_SHAPE_SSH_ACTION=accept" \
  "POLICY_SHAPE_SRC=tag_apc_controller_placeholder" \
  "POLICY_SHAPE_DST=tag_proxmox_management_placeholder" \
  "POLICY_SHAPE_USERS=dedicated_automation_user_placeholder" \
  "POLICY_SHAPE_NO_CHECK_ACTION_FOR_AUTOMATION_PATH=yes" \
  "POLICY_SHAPE_KEEP_HUMAN_ADMIN_CHECK_MODE_SEPARATE=yes" \
  "POLICY_SHAPE_NO_WILDCARD_SRC=yes" \
  "POLICY_SHAPE_NO_WILDCARD_DST=yes" \
  "POLICY_SHAPE_NO_WILDCARD_USERS=yes" \
  "POLICY_SHAPE_NO_BROAD_ROOT_ACCESS=yes" \
  "REVIEW_CHECK_CONTROLLER_SOURCE_SCOPE=yes" \
  "REVIEW_CHECK_PROXMOX_DESTINATION_SCOPE=yes" \
  "REVIEW_CHECK_AUTOMATION_USER_SCOPE=yes" \
  "REVIEW_CHECK_TAG_OWNER_SCOPE=yes" \
  "REVIEW_CHECK_ROLLBACK_PLAN_PRESENT=yes" \
  "ROLLBACK_PLAN_REQUIRED=yes" \
  "ROLLBACK_PLAN_NO_WORKER_START=yes" \
  "ROLLBACK_PLAN_NO_RUNTIME_ACTIVATION=yes" \
  "POST_CHANGE_VALIDATION_REQUIRED=yes" \
  "POST_CHANGE_VALIDATION_PHASE=phase-14j-es-tailscale-ssh-policy-post-change-read-only-validation" \
  "TAILSCALE_ACL_MUTATION=requires_future_explicit_approval" \
  "TAILSCALE_ADMIN_CONSOLE_CHANGE=requires_future_explicit_approval" \
  "WORKER_START=not_allowed" \
  "RUNTIME_ACTIVATION=not_allowed" \
  "APPROVAL_PHRASE_REQUIRED_FOR_NEXT_MUTATION=yes" \
  "APP_SOURCE_MUTATION=not_performed" \
  "PRODUCTION_DB_MUTATION=not_performed" \
  "JOB_MUTATION=not_performed" \
  "CONTROLLER_SERVICE_RESTART_RELOAD=not_performed" \
  "PROXMOX_SERVICE_RESTART_RELOAD=not_performed" \
  "FIREWALL_MUTATION=not_performed" \
  "SSH_CONFIG_MUTATION=not_performed" \
  "LAN_FIREWALL_TCP22_OPEN=not_performed" \
  "TAILSCALE_ACL_MUTATION=not_performed" \
  "TAILSCALE_ADMIN_CONSOLE_CHANGE=not_performed" \
  "PROXMOX_USER_MUTATION=not_performed" \
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
  "RAW_TAILSCALE_AUTH_URL_RECORDING=not_performed" \
  "HASH_ONLY_CONFIGURED_TARGET_OUTPUT=yes" \
  "DO_NOT_RERUN_14J_AG_APPLY_WRAPPER=preserved" \
  "NO_SECRETS_PRINTED=yes" \
  "TAILSCALE_SSH_POLICY_APPROVAL_PACKET_RESULT=ready_for_user_admin_review" \
  "NEXT_SAFE_PHASE=tailscale_ssh_policy_user_admin_review_required"; do
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

echo "PASS: production runtime remains unchanged after ER packet"
echo "PASS: Phase 14J-ER Tailscale SSH policy approval packet smoke passed"
