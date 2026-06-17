#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-eo-tailscale-ssh-auth-policy-repair-plan"
DOC="docs/${PHASE}.md"
DB="edge_queue.sqlite3"
SERVICE="edge-queue-controller.service"

echo "=== Phase 14J-EO smoke: Tailscale SSH auth policy repair plan ==="

test -f "$DOC"
echo "PASS: EO doc exists"

for marker in \
  "PHASE_14J_EO_TAILSCALE_SSH_AUTH_POLICY_REPAIR_PLAN" \
  "MUTATION_SCOPE=docs_smoke_only_tailscale_ssh_auth_policy_repair_plan" \
  "SAFE_TRAP_PATTERN=yes" \
  "NO_TRAP_EXIT=yes" \
  "EN_RESULT=completed_tailscale_auth_or_acl_additional_check_required" \
  "CONFIGURED_TAILSCALE_TARGET_NETWORK_REACHABLE=yes" \
  "SSH_CONFIG_EXPANSION_WORKS=yes" \
  "NONINTERACTIVE_SSH_READY=no" \
  "TAILSCALE_AUTH_OR_ACL_ISSUE_CONFIRMED=yes" \
  "TAILSCALE_ADDITIONAL_CHECK_REQUIRED=yes" \
  "DIRECT_LAN_SSHD_REQUIRED=no" \
  "LAN_FIREWALL_TCP22_OPEN_REQUIRED=no" \
  "GUARDED_WORKER_START_REMAINS_BLOCKED=yes" \
  "OFFICIAL_TAILSCALE_DOCS_REVIEWED_FOR_EO=yes" \
  "OFFICIAL_TAILSCALE_SSH_CHECK_MODE_REAUTH_REQUIRED=yes" \
  "OFFICIAL_TAILSCALE_SSH_CHECK_MODE_USES_SIGNIN_URL=yes" \
  "OFFICIAL_TAILSCALE_SSH_CHECK_MODE_CONTROLLED_BY_SSH_POLICY_ACTION_CHECK=yes" \
  "OFFICIAL_TAILSCALE_SSH_CHECK_MODE_OPTIONAL_NOT_DEFAULT=yes" \
  "OFFICIAL_TAILSCALE_CHECK_MODE_CAN_AFFECT_AUTOMATION=yes" \
  "OFFICIAL_TAILSCALE_SECURITY_BEST_PRACTICE_CHECK_MODE_FOR_HIGH_RISK_SSH=yes" \
  "TAILSCALE_SSH_AUTH_POLICY_REPAIR_PLAN=ready" \
  "EO_RECOMMENDATION=prepare_policy_candidate_without_applying" \
  "REQUIRE_OFFICIAL_TAILSCALE_POLICY_REVIEW=yes" \
  "REQUIRE_TAILSCALE_ADMIN_CONSOLE_CHANGE_APPROVAL=yes" \
  "REQUIRE_SOURCE_AND_DESTINATION_NARROWING=yes" \
  "REQUIRE_USER_NARROWING=yes" \
  "REQUIRE_NO_WILDCARD_ROOT_ACCESS=yes" \
  "REQUIRE_ROLLBACK_PLAN=yes" \
  "REQUIRE_EXPLICIT_TAILSCALE_ADMIN_APPROVAL=yes" \
  "REQUIRE_EXPLICIT_POLICY_DIFF_REVIEW=yes" \
  "REQUIRE_EXPLICIT_NO_LAN_FIREWALL_OPEN_CONFIRMATION=yes" \
  "REQUIRE_NO_RAW_TAILSCALE_AUTH_URL_RECORDING=yes" \
  "NEXT_PHASE_NAME=phase-14j-ep-tailscale-ssh-auth-policy-candidate-design" \
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
  "TAILSCALE_SSH_AUTH_POLICY_REPAIR_PLAN_RESULT=ready_for_policy_candidate_design" \
  "NEXT_SAFE_PHASE=tailscale_ssh_auth_policy_candidate_design"; do
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

echo "PASS: production runtime remains unchanged after EO plan"
echo "PASS: Phase 14J-EO Tailscale SSH auth policy repair plan smoke passed"
