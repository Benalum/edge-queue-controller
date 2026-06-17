#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-es-tailscale-ssh-policy-user-admin-review-and-mutation-readiness"
DOC="docs/${PHASE}.md"
DB="edge_queue.sqlite3"
SERVICE="edge-queue-controller.service"

echo "=== Phase 14J-ES smoke: Tailscale SSH policy user/admin review and mutation readiness ==="

test -f "$DOC"
echo "PASS: ES doc exists"

for marker in \
  "PHASE_14J_ES_TAILSCALE_SSH_POLICY_USER_ADMIN_REVIEW_AND_MUTATION_READINESS" \
  "MUTATION_SCOPE=docs_smoke_only_tailscale_ssh_policy_user_admin_review_and_mutation_readiness" \
  "SAFE_TRAP_PATTERN=yes" \
  "NO_TRAP_EXIT=yes" \
  "ER_RESULT=ready_for_user_admin_review" \
  "APPROVAL_PACKET_TARGET_CANDIDATE=Candidate_C_dedicated_tagged_automation_identity" \
  "USER_LOCAL_TAILSCALE_ADMIN_CONSOLE_REVIEW_COMPLETED=yes" \
  "USER_LOCAL_POLICY_REVIEW_COMPLETED=yes" \
  "USER_CONFIRMED_NO_RAW_DEVICE_NAMES_IN_CHAT=yes" \
  "USER_CONFIRMED_NO_RAW_USER_NAMES_IN_CHAT=yes" \
  "USER_CONFIRMED_NO_RAW_SSH_TARGET_IN_CHAT=yes" \
  "USER_CONFIRMED_NO_RAW_KEY_PATH_IN_CHAT=yes" \
  "USER_CONFIRMED_NO_RAW_TAILSCALE_AUTH_URL_IN_CHAT=yes" \
  "USER_APPROVED_PREPARING_GUARDED_MUTATION_REVIEW_PHASE=yes" \
  "CANDIDATE_C_READINESS_PACKET=ready" \
  "CANDIDATE_C_SELECTED=yes" \
  "CANDIDATE_C_POLICY_MUTATION_NOT_APPLIED=yes" \
  "CANDIDATE_C_EXPECTED_ACTION=accept" \
  "CANDIDATE_C_EXPECTED_SOURCE_SCOPE=controller_automation_identity_only" \
  "CANDIDATE_C_EXPECTED_DESTINATION_SCOPE=proxmox_management_destination_only" \
  "CANDIDATE_C_EXPECTED_USER_SCOPE=dedicated_automation_user_only" \
  "CANDIDATE_C_EXPECTED_NO_CHECK_ACTION_FOR_AUTOMATION_PATH=yes" \
  "CANDIDATE_C_EXPECTED_HUMAN_ADMIN_CHECK_MODE_SEPARATE=yes" \
  "CANDIDATE_C_EXPECTED_NO_WILDCARD_SRC=yes" \
  "CANDIDATE_C_EXPECTED_NO_WILDCARD_DST=yes" \
  "CANDIDATE_C_EXPECTED_NO_WILDCARD_USERS=yes" \
  "TAILSCALE_POLICY_MUTATION_READY_FOR_FINAL_APPROVAL_PACKET=yes" \
  "TAILSCALE_POLICY_MUTATION_PERFORMED=no" \
  "TAILSCALE_ADMIN_CONSOLE_CHANGE_PERFORMED=no" \
  "PROXMOX_USER_MUTATION_PERFORMED=no" \
  "SSH_CONFIG_MUTATION_PERFORMED=no" \
  "SERVICE_ENV_MUTATION_PERFORMED=no" \
  "LAN_FIREWALL_TCP22_OPEN_PERFORMED=no" \
  "WORKER_START_PERFORMED=no" \
  "RUNTIME_ACTIVATION_PERFORMED=no" \
  "REQUIRE_FINAL_EXPLICIT_TAILSCALE_POLICY_MUTATION_APPROVAL=yes" \
  "REQUIRE_FINAL_POLICY_DIFF_REVIEW=yes" \
  "REQUIRE_FINAL_ROLLBACK_PLAN_CONFIRMATION=yes" \
  "REQUIRE_FINAL_POST_CHANGE_READ_ONLY_VALIDATION_CONFIRMATION=yes" \
  "REQUIRE_FINAL_NO_LAN_FIREWALL_OPEN_CONFIRMATION=yes" \
  "REQUIRE_FINAL_NO_WORKER_START_CONFIRMATION=yes" \
  "REQUIRE_FINAL_NO_RUNTIME_ACTIVATION_CONFIRMATION=yes" \
  "FUTURE_POLICY_APPLICATION_MODE=user_admin_console_local_manual_change_preferred" \
  "FUTURE_POLICY_APPLICATION_DO_NOT_PASTE_REAL_POLICY=yes" \
  "POST_CHANGE_READ_ONLY_VALIDATION_REQUIRED=yes" \
  "POST_CHANGE_VALIDATION_NEXT_AFTER_MANUAL_POLICY_CHANGE=phase-14j-et-tailscale-ssh-policy-post-change-read-only-validation" \
  "NEXT_PHASE_NAME=phase-14j-et-tailscale-ssh-policy-final-manual-apply-or-post-change-validation-gate" \
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
  "RAW_DEVICE_USER_TAG_NAME_RECORDING=not_performed" \
  "HASH_ONLY_CONFIGURED_TARGET_OUTPUT=yes" \
  "DO_NOT_RERUN_14J_AG_APPLY_WRAPPER=preserved" \
  "NO_SECRETS_PRINTED=yes" \
  "TAILSCALE_SSH_POLICY_USER_ADMIN_REVIEW_AND_MUTATION_READINESS_RESULT=ready_for_final_manual_apply_or_post_change_validation_gate" \
  "NEXT_SAFE_PHASE=tailscale_ssh_policy_final_manual_apply_or_post_change_validation_gate"; do
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

echo "PASS: production runtime remains unchanged after ES readiness packet"
echo "PASS: Phase 14J-ES Tailscale SSH policy user/admin review and mutation readiness smoke passed"
