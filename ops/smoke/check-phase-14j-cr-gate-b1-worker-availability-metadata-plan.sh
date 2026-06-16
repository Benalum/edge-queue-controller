#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-cr-gate-b1-worker-availability-metadata-plan"
DOC="docs/${PHASE}.md"
DB="edge_queue.sqlite3"
SERVICE="edge-queue-controller.service"

echo "=== Phase 14J-CR smoke: Gate B1 worker availability metadata plan ==="

test -f "$DOC"
echo "PASS: CR doc exists"

for marker in \
  "PHASE_14J_CR_GATE_B1_WORKER_AVAILABILITY_METADATA_PLAN" \
  "MUTATION_SCOPE=docs_smoke_only_gate_b1_worker_availability_metadata_plan" \
  "SECURITY_FOLLOWUP_RESULT=smtp_credential_rotated_and_old_key_revoked" \
  "SMTP_ROTATION_RESULT=rotated_loaded_and_provider_verified" \
  "RESEND_OLD_API_KEY_DELETED=reported_by_user" \
  "GATE_B0_PATCH_RESULT=accepts_lane_jobs_and_no_lane_filter_contract_patched" \
  "PATCHED_ACCEPTS_LANE_JOBS_ENFORCEMENT=yes" \
  "PATCHED_NO_LANE_FILTER_PASSTHROUGH=yes" \
  "ACCEPTS_LANE_JOBS_FALSE_REJECTED=verified" \
  "NO_LANE_JOB_DEFAULT_PATH_PASSTHROUGH=verified" \
  "LANE_REQUIRED_WITH_NO_LANE_WORKER_FAILS_SAFE=verified" \
  "GATE_B1_PLAN=temp_db_worker_availability_metadata_smoke" \
  "NEXT_PHASE_NAME=phase-14j-cs-gate-b1-temp-db-worker-availability-metadata-smoke" \
  "TEMP_DB_ONLY=yes" \
  "PRODUCTION_DB_MUTATION=not_performed" \
  "SOURCE_MUTATION=not_performed" \
  "JOB_MUTATION=not_performed" \
  "SERVICE_RESTART_RELOAD=not_performed" \
  "CT101_CALL=not_performed" \
  "MODEL_OLLAMA_CALL=not_performed" \
  "SCHEDULER_LANE_DISPATCH_ACTIVATION=not_performed" \
  "PRIMARY_WORKER_FILTERING_ACTIVATION=not_performed" \
  "PERSISTENT_LANE_WORKER_STARTUP=not_performed" \
  "RUNTIME_ACTIVATION=not_performed" \
  "DO_NOT_RERUN_14J_AG_APPLY_WRAPPER=preserved" \
  "NO_SECRETS_PRINTED=yes" \
  "GATE_B1_METADATA_PLAN_RESULT=ready_for_temp_db_worker_availability_smoke" \
  "NEXT_SAFE_PHASE=gate_b1_temp_db_worker_availability_metadata_smoke"; do
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

echo "service_active=${service_active}"
echo "service_enabled=${service_enabled}"
echo "service_EDGE_PERSISTENT_LANE_WORKERS_ENABLED=${service_flag:-<unset>}"
echo "sqlite_quick_check=${quick_check}"
echo "worker_facts=${worker_facts}"

IFS=',' read -r worker_count lane_enabled non_default_lane non_primary_role <<< "$worker_facts"

test "$service_active" = "active"
test "$service_enabled" = "enabled"
test -z "$service_flag"
test "$quick_check" = "ok"
test "$lane_enabled" = "0"
test "$non_default_lane" = "0"
test "$non_primary_role" = "0"

echo "PASS: production runtime remains default-off"
echo "PASS: Phase 14J-CR Gate B1 metadata plan smoke passed"
