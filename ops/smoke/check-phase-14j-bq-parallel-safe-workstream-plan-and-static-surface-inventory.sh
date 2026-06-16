#!/usr/bin/env bash
set -euo pipefail

echo "=== Phase 14J-BQ smoke: parallel safe workstream plan and static surface inventory ==="

DOC="docs/phase-14j-bq-parallel-safe-workstream-plan-and-static-surface-inventory.md"
SMOKE="ops/smoke/check-phase-14j-bq-parallel-safe-workstream-plan-and-static-surface-inventory.sh"
DB="edge_queue.sqlite3"
SERVICE="edge-queue-controller"

echo
echo "=== required files ==="
test -f "$DOC"
test -f "$SMOKE"
echo "PASS: required BQ doc/smoke files exist"

echo
echo "=== doc markers ==="
for marker in \
  "PHASE_14J_BQ_PARALLEL_SAFE_WORKSTREAM_PLAN_AND_STATIC_SURFACE_INVENTORY" \
  "MUTATION_SCOPE=docs_smoke_only_static_inventory" \
  "SOURCE_REFRESH_CADENCE=milestone_handoff_or_runtime_gate" \
  "TERMINAL_OUTPUT_CURRENT_TRUTH=preferred_when_newer_than_uploaded_source" \
  "SAFE_BATCH_MODE=enabled_for_green_and_guarded_source_phases" \
  "PARALLELIZE_SAFE_GREEN_WORK" \
  "SERIALIZE_RUNTIME_CHANGES" \
  "RUNTIME_ACTIVATION=not_performed" \
  "SERVICE_RESTART_RELOAD=not_performed" \
  "CT101_MODEL_OLLAMA_CALLS=forbidden" \
  "CT101_MODEL_JOB_MUTATION=not_performed" \
  "DB_MUTATION=not_performed" \
  "JOB_MUTATION=not_performed" \
  "LANE_WORKER_ENABLEMENT=not_performed" \
  "SCHEDULER_LANE_DISPATCH_ACTIVATION=not_performed" \
  "PRIMARY_WORKER_FILTERING_ACTIVATION=not_performed" \
  "ROUTER_MODEL_SELECTION_ACTIVATION=not_performed" \
  "WARMUP_EXECUTION_ACTIVATION=not_performed" \
  "DO_NOT_RERUN_14J_AG_APPLY_WRAPPER" \
  "NEXT_EXECUTION_STRATEGY=batch_safe_independent_workstreams" \
  "NEXT_SAFE_PHASE=phase_14j_br_batched_static_contract_inventory_and_first_safe_patch_candidates" \
  "ACTIVATION_REQUIRES_EXPLICIT_USER_APPROVAL"
do
  grep -F "$marker" "$DOC" >/dev/null
  echo "PASS: doc marker found: $marker"
done

echo
echo "=== static workstream headings ==="
for marker in \
  "Workstream A - Lane worker activation safety" \
  "Workstream B - Scheduler and primary-worker filtering" \
  "Workstream C - Router and warmup" \
  "Workstream D - Study and Companion product polish" \
  "Workstream E - Profile, Account, Credits, Admin, System" \
  "Workstream F - Calendar" \
  "Workstream G - PPB / developer acceleration"
do
  grep -F "$marker" "$DOC" >/dev/null
  echo "PASS: workstream heading found: $marker"
done

echo
echo "=== source activation safety markers still present ==="
for marker in \
  "def _phase14j_lane_workers_enabled" \
  "def _phase14j_default_off_worker_registration_metadata" \
  "def _phase14j_job_lane_metadata" \
  "def _phase14j_worker_lane_metadata" \
  "def _phase14j_worker_eligible_for_job" \
  "def _phase14j_filter_workers_for_lane" \
  "phase14j_lane_scheduler_gate_enabled = _phase14j_lane_workers_enabled()" \
  "workers = _phase14j_filter_workers_for_lane(workers, job)" \
  "registration_metadata = _phase14j_default_off_worker_registration_metadata()" \
  "\"reason_code\": \"lane_gate_disabled\""
do
  grep -F "$marker" edge_controller.py >/dev/null
  echo "PASS: source marker found: $marker"
done

echo
echo "=== python compile ==="
python3 -m py_compile edge_controller.py
echo "PASS: edge_controller.py compiles"

echo
echo "=== SQLite read-only quick_check ==="
quick_check="$(sqlite3 "file:${DB}?mode=ro" 'PRAGMA quick_check;')"
printf 'quick_check=%s\n' "$quick_check"
test "$quick_check" = "ok"
echo "PASS: SQLite read-only quick_check ok"

echo
echo "=== worker/default-off counts, read-only ==="
worker_count="$(sqlite3 "file:${DB}?mode=ro" 'SELECT COUNT(*) FROM workers;')"
lane_enabled_worker_count="$(sqlite3 "file:${DB}?mode=ro" "SELECT COALESCE(SUM(CASE WHEN COALESCE(accepts_lane_jobs,0) NOT IN (0,'0','false','False','') THEN 1 ELSE 0 END),0) FROM workers;")"
non_default_worker_lane_count="$(sqlite3 "file:${DB}?mode=ro" "SELECT COALESCE(SUM(CASE WHEN COALESCE(worker_lane,'primary') <> 'primary' THEN 1 ELSE 0 END),0) FROM workers;")"
non_primary_worker_role_count="$(sqlite3 "file:${DB}?mode=ro" "SELECT COALESCE(SUM(CASE WHEN COALESCE(worker_role,'primary') <> 'primary' THEN 1 ELSE 0 END),0) FROM workers;")"

printf 'worker_count=%s\n' "$worker_count"
printf 'lane_enabled_worker_count=%s\n' "$lane_enabled_worker_count"
printf 'non_default_worker_lane_count=%s\n' "$non_default_worker_lane_count"
printf 'non_primary_worker_role_count=%s\n' "$non_primary_worker_role_count"

test "$worker_count" = "0"
test "$lane_enabled_worker_count" = "0"
test "$non_default_worker_lane_count" = "0"
test "$non_primary_worker_role_count" = "0"

echo "PASS: worker registry remains default-off"

echo
echo "=== persistent lane worker flag guard ==="
shell_flag="${EDGE_PERSISTENT_LANE_WORKERS_ENABLED:-}"
printf 'shell_EDGE_PERSISTENT_LANE_WORKERS_ENABLED=%s\n' "${shell_flag:-<unset>}"

case "${shell_flag,,}" in
  ""|"0"|"false"|"no"|"off")
    echo "PASS: shell persistent lane worker flag absent/disabled"
    ;;
  *)
    echo "FAIL: shell persistent lane worker flag appears enabled"
    exit 1
    ;;
esac

service_env="$(systemctl show "$SERVICE" -p Environment --value 2>/dev/null || true)"
service_flag="$(printf '%s\n' "$service_env" | tr ' ' '\n' | grep -E '^EDGE_PERSISTENT_LANE_WORKERS_ENABLED=' || true)"
printf 'service_EDGE_PERSISTENT_LANE_WORKERS_ENABLED=%s\n' "${service_flag:-<unset>}"

if [ -z "$service_flag" ]; then
  echo "PASS: service persistent lane worker flag absent"
else
  service_value="${service_flag#*=}"
  case "${service_value,,}" in
    ""|"0"|"false"|"no"|"off")
      echo "PASS: service persistent lane worker flag disabled"
      ;;
    *)
      echo "FAIL: service persistent lane worker flag appears enabled"
      exit 1
      ;;
  esac
fi

echo
echo "=== no runtime activation confirmation ==="
grep -F "RUNTIME_ACTIVATION=not_performed" "$DOC" >/dev/null
grep -F "SERVICE_RESTART_RELOAD=not_performed" "$DOC" >/dev/null
grep -F "DB_MUTATION=not_performed" "$DOC" >/dev/null
grep -F "JOB_MUTATION=not_performed" "$DOC" >/dev/null
grep -F "LANE_WORKER_ENABLEMENT=not_performed" "$DOC" >/dev/null
grep -F "ACTIVATION_REQUIRES_EXPLICIT_USER_APPROVAL" "$DOC" >/dev/null
echo "PASS: BQ confirms no runtime activation and explicit approval boundary"

echo
echo "PASS: Phase 14J-BQ parallel safe workstream plan smoke passed"
