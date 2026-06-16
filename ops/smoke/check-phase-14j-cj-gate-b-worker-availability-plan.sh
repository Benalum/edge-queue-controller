#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-cj-gate-b-worker-availability-plan"
DOC="docs/${PHASE}.md"
DB="edge_queue.sqlite3"
SERVICE="edge-queue-controller.service"

echo "=== Phase 14J-CJ smoke: Gate B worker availability plan ==="

test -f "$DOC"
echo "PASS: CJ doc exists"

for marker in \
  "PHASE_14J_CJ_GATE_B_WORKER_AVAILABILITY_PLAN" \
  "MUTATION_SCOPE=docs_smoke_only_gate_b_worker_availability_plan" \
  "GATE_A_CONTROLLER_SIDE_FLAG_TEST=passed" \
  "CH_ROLLBACK_PERFORMED=yes" \
  "FINAL_STATE_DEFAULT_OFF=yes" \
  "RUNTIME_ACTIVATION_LEFT_ENABLED=no" \
  "Gate B0 - synthetic worker availability smoke" \
  "Gate C - scheduler lane dispatch" \
  "Gate D - primary-worker filtering" \
  "DB_MUTATION=not_performed" \
  "JOB_MUTATION=not_performed" \
  "CT101_CALL=not_performed" \
  "MODEL_OLLAMA_CALL=not_performed" \
  "SCHEDULER_LANE_DISPATCH_ACTIVATION=not_performed" \
  "PRIMARY_WORKER_FILTERING_ACTIVATION=not_performed" \
  "PERSISTENT_LANE_WORKER_STARTUP=not_performed" \
  "DO_NOT_RERUN_14J_AG_APPLY_WRAPPER=preserved" \
  "_phase14j_lane_workers_enabled" \
  "_phase14j_filter_workers_for_lane" \
  "SECURITY_FOLLOWUP_REQUIRED=rotate_exposed_smtp_credential" \
  "NEXT_SAFE_PHASE=gate_b0_synthetic_worker_availability_smoke_artifact"; do
  grep -F "$marker" "$DOC" >/dev/null
  echo "PASS: marker found: $marker"
done

service_active="$(systemctl is-active "$SERVICE" 2>/dev/null || true)"
echo "service_active=${service_active}"
test "$service_active" = "active"
echo "PASS: service active"

service_flag="$(systemctl show "$SERVICE" -p Environment --value 2>/dev/null | tr ' ' '\n' | grep '^EDGE_PERSISTENT_LANE_WORKERS_ENABLED=' || true)"
echo "service_EDGE_PERSISTENT_LANE_WORKERS_ENABLED=${service_flag:-<unset>}"
test -z "$service_flag"
echo "PASS: service persistent lane flag absent/default-off"

quick_check="$(sqlite3 "file:${PWD}/${DB}?mode=ro" "PRAGMA quick_check;")"
echo "sqlite_quick_check=${quick_check}"
test "$quick_check" = "ok"
echo "PASS: sqlite quick_check ok"

lane_enabled="$(sqlite3 "file:${PWD}/${DB}?mode=ro" "SELECT COALESCE(SUM(CASE WHEN COALESCE(accepts_lane_jobs,0) NOT IN (0,'0','false','False','') THEN 1 ELSE 0 END),0) FROM workers;")"
non_default_lane="$(sqlite3 "file:${PWD}/${DB}?mode=ro" "SELECT COALESCE(SUM(CASE WHEN COALESCE(worker_lane,'') NOT IN ('','primary') THEN 1 ELSE 0 END),0) FROM workers;")"
non_primary_role="$(sqlite3 "file:${PWD}/${DB}?mode=ro" "SELECT COALESCE(SUM(CASE WHEN COALESCE(worker_role,'primary') <> 'primary' THEN 1 ELSE 0 END),0) FROM workers;")"

echo "lane_enabled_worker_count=${lane_enabled}"
echo "non_default_worker_lane_count=${non_default_lane}"
echo "non_primary_worker_role_count=${non_primary_role}"

test "$lane_enabled" = "0"
test "$non_default_lane" = "0"
test "$non_primary_role" = "0"
echo "PASS: worker lane state remains default-off"

echo "PASS: Phase 14J-CJ Gate B worker availability plan smoke passed"
