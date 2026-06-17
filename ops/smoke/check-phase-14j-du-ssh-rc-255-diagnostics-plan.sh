#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-du-ssh-rc-255-diagnostics-plan"
DOC="docs/${PHASE}.md"
DB="edge_queue.sqlite3"
SERVICE="edge-queue-controller.service"

echo "=== Phase 14J-DU smoke: SSH rc 255 diagnostics plan ==="

test -f "$DOC"
echo "PASS: DU doc exists"

for marker in \
  "PHASE_14J_DU_SSH_RC_255_DIAGNOSTICS_PLAN" \
  "MUTATION_SCOPE=docs_smoke_only_ssh_rc_255_diagnostics_plan" \
  "PROXMOX_INVENTORY_SSH_TIMEOUT_READ_ONLY_DIAGNOSTICS_RESULT=completed" \
  "DT_NARROWED_ROOT_CAUSE_AREA=ssh_connection_or_auth_path_failure_before_inventory_output" \
  "PROXMOX_INVENTORY_TIMEOUT_CAUSE_REFINED=ssh_rc_255_before_inventory_command_output" \
  "SSH_HOST_RESOLUTION_RESULT=resolved" \
  "TAILSCALE_BACKEND_STATE=Running" \
  "SSH_REACHABILITY_TRUE_RC=255" \
  "SSH_PVESH_PRESENT_RC=255" \
  "SSH_PROXMOX_INVENTORY_RC=255" \
  "SSH_RC_255_DIAGNOSTICS_PLAN=ready_for_explicit_read_only_diagnostics" \
  "CHECK_TAILSCALE_PEER_MATCH_REDACTED=yes" \
  "CHECK_TCP_PORT_22_REACHABILITY_SHORT_TIMEOUT=yes" \
  "CHECK_SSH_BATCHMODE_VERBOSE_SANITIZED=yes" \
  "CHECK_SSH_AUTH_FAILURE_CLASSIFICATION=yes" \
  "CHECK_SSH_HOSTKEY_FAILURE_CLASSIFICATION=yes" \
  "CHECK_SSH_TIMEOUT_FAILURE_CLASSIFICATION=yes" \
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
  "REQUIRE_SANITIZED_OUTPUT=yes" \
  "REQUIRE_NO_SECRET_PRINTING=yes" \
  "REQUIRE_SHORT_TIMEOUTS=yes" \
  "REQUIRE_NO_FULL_SYSTEMD_ENVIRONMENT_PRINT=yes" \
  "REQUIRE_NO_RAW_SSH_TARGET_PRINTING=yes" \
  "REQUIRE_NO_RAW_KEY_PATH_PRINTING=yes" \
  "GUARDED_WORKER_START_REMAINS_BLOCKED=yes" \
  "SSH_RC_255_DIAGNOSIS_REQUIRED=yes" \
  "NEXT_PHASE_NAME=phase-14j-dv-ssh-rc-255-read-only-diagnostics" \
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
  "DO_NOT_RERUN_14J_AG_APPLY_WRAPPER=preserved" \
  "NO_SECRETS_PRINTED=yes" \
  "SSH_RC_255_DIAGNOSTICS_PLAN_RESULT=ready_for_explicit_read_only_diagnostics" \
  "NEXT_SAFE_PHASE=ssh_rc_255_read_only_diagnostics_requires_approval"; do
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

echo "PASS: production runtime remains unchanged after DU plan"
echo "PASS: Phase 14J-DU SSH rc 255 diagnostics plan smoke passed"
