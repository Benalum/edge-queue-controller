#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-ej-proxmox-ssh-tailscale-only-management-path-decision"
DOC="docs/${PHASE}.md"
DB="edge_queue.sqlite3"
SERVICE="edge-queue-controller.service"

echo "=== Phase 14J-EJ smoke: Proxmox SSH Tailscale-only management path decision ==="

test -f "$DOC"
echo "PASS: EJ decision doc exists"

for marker in \
  "PHASE_14J_EJ_PROXMOX_SSH_TAILSCALE_ONLY_MANAGEMENT_PATH_DECISION" \
  "MUTATION_SCOPE=docs_smoke_only_proxmox_ssh_tailscale_only_management_path_decision" \
  "EH_RESULT=completed_local_route_exists_but_tcp22_timeout" \
  "EI_RESULT=ready_for_read_only_diagnostics" \
  "LAN_CANDIDATE_DIFFERED_FROM_TAILSCALE_ENDPOINT=yes" \
  "LAN_CANDIDATE_TCP22_TIMEOUT=yes" \
  "DIRECT_LAN_SSHD_CANDIDATE_USABLE=no" \
  "GUARDED_WORKER_START_REMAINS_BLOCKED=yes" \
  "USER_REPORTED_LIKELY_FIREWALL_POLICY=tailscale_only_ssh_to_reduce_local_attack_surface" \
  "SECURITY_DECISION=preserve_tailscale_only_proxmox_ssh_management" \
  "DO_NOT_OPEN_LAN_SSH_FOR_AUTOMATION=yes" \
  "DO_NOT_WEAKEN_PROXMOX_FIREWALL_FOR_THIS_PHASE=yes" \
  "DO_NOT_PURSUE_DIRECT_LAN_SSHD_AS_REQUIRED_PATH=yes" \
  "NEXT_PHASE_NAME=phase-14j-ek-configured-tailscale-proxmox-management-path-readiness-plan" \
  "USE_CONFIGURED_TAILSCALE_PROXMOX_MANAGEMENT_PATH=yes" \
  "DO_NOT_REQUIRE_DIRECT_LAN_SSHD=yes" \
  "DO_NOT_OPEN_LAN_FIREWALL_TCP22=yes" \
  "DO_NOT_MUTATE_FIREWALL=yes" \
  "DO_NOT_MUTATE_SSH_CONFIG=yes" \
  "DO_NOT_RESTART_PROXMOX_SSHD=yes" \
  "DO_NOT_START_WORKERS=yes" \
  "DO_NOT_ACTIVATE_RUNTIME=yes" \
  "REQUIRE_EXPLICIT_APPROVAL_BEFORE_ANY_OPERATIONAL_CHANGE=yes" \
  "APP_SOURCE_MUTATION=not_performed" \
  "PRODUCTION_DB_MUTATION=not_performed" \
  "JOB_MUTATION=not_performed" \
  "CONTROLLER_SERVICE_RESTART_RELOAD=not_performed" \
  "PROXMOX_SERVICE_RESTART_RELOAD=not_performed" \
  "FIREWALL_MUTATION=not_performed" \
  "SSH_CONFIG_MUTATION=not_performed" \
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
  "HASH_ONLY_HOSTKEY_OUTPUT=yes" \
  "DO_NOT_RERUN_14J_AG_APPLY_WRAPPER=preserved" \
  "NO_SECRETS_PRINTED=yes" \
  "PROXMOX_SSH_TAILSCALE_ONLY_MANAGEMENT_PATH_DECISION_RESULT=accepted" \
  "NEXT_SAFE_PHASE=configured_tailscale_proxmox_management_path_readiness_plan"; do
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

echo "PASS: production runtime remains unchanged after EJ decision"
echo "PASS: Phase 14J-EJ Proxmox SSH Tailscale-only management path decision smoke passed"
