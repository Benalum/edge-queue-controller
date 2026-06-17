#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-eq-tailscale-ssh-policy-candidate-review-plan"
DOC="docs/${PHASE}.md"
DB="edge_queue.sqlite3"
SERVICE="edge-queue-controller.service"

echo "=== Phase 14J-EQ smoke: Tailscale SSH policy candidate review plan ==="

test -f "$DOC"
echo "PASS: EQ doc exists"

for marker in \
  "PHASE_14J_EQ_TAILSCALE_SSH_POLICY_CANDIDATE_REVIEW_PLAN" \
  "MUTATION_SCOPE=docs_smoke_only_tailscale_ssh_policy_candidate_review_plan" \
  "SAFE_TRAP_PATTERN=yes" \
  "NO_TRAP_EXIT=yes" \
  "EP_RESULT=ready_for_policy_candidate_review_plan" \
  "EP_RECOMMENDATION=prefer_candidate_c_then_candidate_b_as_fallback" \
  "NONINTERACTIVE_SSH_READY=no" \
  "TAILSCALE_ADDITIONAL_CHECK_REQUIRED=yes" \
  "DIRECT_LAN_SSHD_REQUIRED=no" \
  "LAN_FIREWALL_TCP22_OPEN_REQUIRED=no" \
  "GUARDED_WORKER_START_REMAINS_BLOCKED=yes" \
  "TAILSCALE_SSH_POLICY_CANDIDATE_REVIEW_PLAN=ready" \
  "CANDIDATE_A_REVIEW=not_selected_for_runtime_automation" \
  "CANDIDATE_B_REVIEW=acceptable_fallback_if_dedicated_tags_are_not_ready" \
  "CANDIDATE_C_REVIEW=selected_for_approval_packet_design" \
  "CANDIDATE_C_SELECTED=yes" \
  "CANDIDATE_D_REVIEW=parked_alternative" \
  "CANDIDATE_D_SELECTED=no" \
  "EQ_SELECTED_PATH=dedicated_tagged_automation_identity_candidate_c" \
  "EQ_FALLBACK_PATH=narrow_tailscale_ssh_accept_rule_candidate_b" \
  "EQ_PARKED_PATH=standard_openssh_over_tailscale_ip_candidate_d" \
  "REQUIRE_APPROVAL_PACKET_POLICY_INTENT=yes" \
  "REQUIRE_APPROVAL_PACKET_POLICY_SHAPE_PLACEHOLDER_ONLY=yes" \
  "REQUIRE_APPROVAL_PACKET_NO_RAW_DEVICE_NAMES_IN_CHAT=yes" \
  "REQUIRE_APPROVAL_PACKET_SOURCE_SCOPE=yes" \
  "REQUIRE_APPROVAL_PACKET_DESTINATION_SCOPE=yes" \
  "REQUIRE_APPROVAL_PACKET_USER_SCOPE=yes" \
  "REQUIRE_APPROVAL_PACKET_TAG_OWNER_REVIEW=yes" \
  "REQUIRE_APPROVAL_PACKET_ROLLBACK_PLAN=yes" \
  "REQUIRE_APPROVAL_PACKET_POST_CHANGE_READ_ONLY_VALIDATION=yes" \
  "TAILSCALE_ACL_MUTATION=not_allowed" \
  "TAILSCALE_ADMIN_CONSOLE_CHANGE=not_allowed" \
  "PROXMOX_USER_MUTATION=not_allowed" \
  "SSH_CONFIG_MUTATION=not_allowed" \
  "FIREWALL_MUTATION=not_allowed" \
  "LAN_FIREWALL_TCP22_OPEN=not_allowed" \
  "SERVICE_ENV_MUTATION=not_allowed" \
  "WORKER_START=not_allowed" \
  "RUNTIME_ACTIVATION=not_allowed" \
  "REQUIRE_EXPLICIT_USER_APPROVAL_FOR_TAILSCALE_POLICY_MUTATION=yes" \
  "REQUIRE_EXPLICIT_POLICY_DIFF_REVIEW=yes" \
  "REQUIRE_EXPLICIT_ROLLBACK_PLAN=yes" \
  "REQUIRE_EXPLICIT_POST_CHANGE_READ_ONLY_DIAGNOSTIC=yes" \
  "NEXT_PHASE_NAME=phase-14j-er-tailscale-ssh-policy-approval-packet" \
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
  "TAILSCALE_SSH_POLICY_CANDIDATE_REVIEW_PLAN_RESULT=ready_for_candidate_c_approval_packet" \
  "NEXT_SAFE_PHASE=tailscale_ssh_policy_approval_packet"; do
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

echo "PASS: production runtime remains unchanged after EQ plan"
echo "PASS: Phase 14J-EQ Tailscale SSH policy candidate review plan smoke passed"
