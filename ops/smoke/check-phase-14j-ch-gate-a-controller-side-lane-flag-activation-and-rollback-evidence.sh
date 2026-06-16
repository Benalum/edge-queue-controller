#!/usr/bin/env bash
set -euo pipefail

DOC="docs/phase-14j-ch-gate-a-controller-side-lane-flag-activation-and-rollback-evidence.md"
DB="edge_queue.sqlite3"
SERVICE="edge-queue-controller.service"

echo "=== Phase 14J-CH smoke: Gate A activation and rollback evidence ==="

test -f "$DOC"
echo "PASS: CH doc exists"

for marker in \
  "PHASE_14J_CH_GATE_A_CONTROLLER_SIDE_LANE_FLAG_ACTIVATION_AND_ROLLBACK_EVIDENCE" \
  "MUTATION_SCOPE=bounded_runtime_service_env_activation_and_rollback" \
  "APPROVED_RUNTIME_SCOPE=edge_queue_controller_service_env_only" \
  "DB_MUTATION=not_performed_by_phase" \
  "JOB_MUTATION=not_performed_by_phase" \
  "CT101_CALL=not_performed" \
  "MODEL_OLLAMA_CALL=not_performed" \
  "SCHEDULER_LANE_DISPATCH_ACTIVATION=not_performed" \
  "PRIMARY_WORKER_FILTERING_ACTIVATION=not_performed" \
  "PERSISTENT_LANE_WORKER_STARTUP=not_performed" \
  "ROUTER_ROLLOUT=not_performed" \
  "WARMUP_EXECUTION=not_performed" \
  "DO_NOT_RERUN_14J_AG_APPLY_WRAPPER=preserved" \
  "RUNTIME_GATE_TEMPORARILY_ACTIVATED=yes" \
  "ACTIVATION_SMOKE=passed" \
  "ROLLBACK_PERFORMED=yes" \
  "ROLLBACK_SMOKE=passed" \
  "FINAL_STATE_DEFAULT_OFF=yes" \
  "RUNTIME_ACTIVATION_LEFT_ENABLED=no" \
  "NEXT_SAFE_PHASE=decide_whether_to_leave_gate_a_enabled_or_prepare_gate_b_worker_availability"; do
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
echo "PASS: service persistent lane flag absent after rollback"

quick_check="$(sqlite3 "file:$PWD/$DB?mode=ro" "PRAGMA quick_check;")"
echo "sqlite_quick_check=${quick_check}"
test "$quick_check" = "ok"
echo "PASS: sqlite quick_check ok"

lane_enabled="$(sqlite3 "file:$PWD/$DB?mode=ro" "SELECT COALESCE(SUM(CASE WHEN COALESCE(accepts_lane_jobs,0) NOT IN (0,'0','false','False','') THEN 1 ELSE 0 END),0) FROM workers;")"
echo "lane_enabled_worker_count=${lane_enabled}"
test "$lane_enabled" = "0"
echo "PASS: lane-enabled workers remain zero"

echo "PASS: Phase 14J-CH Gate A activation and rollback evidence smoke passed"
