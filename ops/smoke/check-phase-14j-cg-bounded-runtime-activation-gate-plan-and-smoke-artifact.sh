#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-cg-bounded-runtime-activation-gate-plan-and-smoke-artifact"
DOC="docs/${PHASE}.md"
DB="edge_queue.sqlite3"
SERVICE="edge-queue-controller"

fail=0

require_file() {
  local path="$1"
  if [ ! -f "$path" ]; then
    echo "FAIL: missing file: $path"
    fail=1
  else
    echo "PASS: exists: $path"
  fi
}

require_marker() {
  local marker="$1"
  if ! grep -F "$marker" "$DOC" >/dev/null; then
    echo "FAIL: missing marker: $marker"
    fail=1
  else
    echo "PASS: marker found: $marker"
  fi
}

echo "=== Phase 14J-CG smoke: bounded runtime activation gate plan ==="

require_file "$DOC"
require_file "$DB"

for marker in \
  "PHASE_14J_CG_BOUNDED_RUNTIME_ACTIVATION_GATE_PLAN_AND_SMOKE_ARTIFACT" \
  "MUTATION_SCOPE=docs_smoke_only_activation_gate_plan" \
  "RUNTIME_ACTIVATION=not_performed" \
  "PERSISTENT_LANE_WORKERS_ENABLED=not_enabled" \
  "SCHEDULER_LANE_DISPATCH_ACTIVATION=not_performed" \
  "PRIMARY_WORKER_FILTERING_ACTIVATION=not_performed" \
  "CT101_MODEL_JOB_MUTATION=not_performed" \
  "SERVICE_RESTART_RELOAD=not_performed" \
  "DB_MUTATION=not_performed" \
  "PRODUCTION_JOB_MUTATION=not_performed" \
  "DO_NOT_RERUN_14J_AG_APPLY_WRAPPER=preserved" \
  "SOURCE_BOOTSTRAP_CORRECTION=worker_registry_to_workers" \
  "ACTUAL_WORKER_TABLE=workers" \
  "ACTIVATION_APPROVAL_REQUIRED=yes" \
  "ROLLBACK_REQUIRED_BEFORE_RUNTIME=yes" \
  "RUNTIME_ACTIVATION_BLOCKED_UNTIL_EXPLICIT_USER_APPROVAL=yes" \
  "NEXT_SAFE_PHASE=bounded_runtime_activation_gate_preflight_or_explicit_activation_request"; do
  require_marker "$marker"
done

echo
echo "=== sqlite read-only checks ==="
quick_check="$(sqlite3 "file:${PWD}/${DB}?mode=ro" "PRAGMA quick_check;")"
echo "sqlite_quick_check=${quick_check}"
if [ "$quick_check" != "ok" ]; then
  echo "FAIL: sqlite quick_check failed"
  fail=1
else
  echo "PASS: sqlite quick_check ok"
fi

workers_table_count="$(sqlite3 "file:${PWD}/${DB}?mode=ro" "SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='workers';")"
echo "workers_table_count=${workers_table_count}"
if [ "$workers_table_count" != "1" ]; then
  echo "FAIL: workers table not found"
  fail=1
else
  echo "PASS: workers table exists"
fi

cols="$(sqlite3 "file:${PWD}/${DB}?mode=ro" "PRAGMA table_info(workers);" | awk -F'|' '{print $2}' | sort)"
for col in worker_role worker_lane accepts_lane_jobs capabilities disabled current_running_jobs state computed_health; do
  if ! printf '%s\n' "$cols" | grep -Fx "$col" >/dev/null; then
    echo "FAIL: missing canonical worker lane metadata column: $col"
    fail=1
  else
    echo "PASS: canonical column present: $col"
  fi
done

if printf '%s\n' "$cols" | grep -Fx "disabled_reason" >/dev/null; then
  echo "FAIL: disabled_reason is present but is not canonical for Phase 14J"
  fail=1
else
  echo "PASS: disabled_reason not required/present as canonical column"
fi

lane_enabled_worker_count="$(sqlite3 "file:${PWD}/${DB}?mode=ro" "SELECT COALESCE(SUM(CASE WHEN COALESCE(accepts_lane_jobs,0) NOT IN (0,'0','false','False','') THEN 1 ELSE 0 END),0) FROM workers;")"
non_default_worker_lane_count="$(sqlite3 "file:${PWD}/${DB}?mode=ro" "SELECT COALESCE(SUM(CASE WHEN COALESCE(worker_lane,'') NOT IN ('','primary') THEN 1 ELSE 0 END),0) FROM workers;")"
non_primary_worker_role_count="$(sqlite3 "file:${PWD}/${DB}?mode=ro" "SELECT COALESCE(SUM(CASE WHEN COALESCE(worker_role,'primary') <> 'primary' THEN 1 ELSE 0 END),0) FROM workers;")"

echo "lane_enabled_worker_count=${lane_enabled_worker_count}"
echo "non_default_worker_lane_count=${non_default_worker_lane_count}"
echo "non_primary_worker_role_count=${non_primary_worker_role_count}"

if [ "$lane_enabled_worker_count" != "0" ]; then
  echo "FAIL: lane-enabled workers exist before activation approval"
  fail=1
else
  echo "PASS: lane-enabled workers remain zero"
fi

if [ "$non_default_worker_lane_count" != "0" ]; then
  echo "FAIL: non-default worker lanes exist before activation approval"
  fail=1
else
  echo "PASS: non-default worker lanes remain zero"
fi

if [ "$non_primary_worker_role_count" != "0" ]; then
  echo "FAIL: non-primary worker roles exist before activation approval"
  fail=1
else
  echo "PASS: non-primary worker roles remain zero"
fi

echo
echo "=== env flag checks, read-only ==="
shell_flag="${EDGE_PERSISTENT_LANE_WORKERS_ENABLED:-<unset>}"
echo "shell_EDGE_PERSISTENT_LANE_WORKERS_ENABLED=${shell_flag}"

case "$shell_flag" in
  1|true|TRUE|True|yes|YES|Yes|on|ON|On)
    echo "FAIL: shell persistent lane worker flag is enabled"
    fail=1
    ;;
  *)
    echo "PASS: shell persistent lane worker flag absent/disabled"
    ;;
esac

service_env="$(systemctl show "$SERVICE" -p Environment --value 2>/dev/null || true)"
service_flag="$(printf '%s\n' "$service_env" | tr ' ' '\n' | grep '^EDGE_PERSISTENT_LANE_WORKERS_ENABLED=' || true)"
echo "service_EDGE_PERSISTENT_LANE_WORKERS_ENABLED=${service_flag:-<unset>}"

if printf '%s\n' "$service_flag" | grep -Eiq '= *(1|true|yes|on)$'; then
  echo "FAIL: service persistent lane worker flag is enabled"
  fail=1
else
  echo "PASS: service persistent lane worker flag absent/disabled"
fi

echo
echo "=== forbidden wrapper reminder ==="
if [ -x "ops/db/apply-default-off-worker-registry-lane-metadata.sh" ]; then
  echo "PASS: apply wrapper exists but was not executed by this smoke"
else
  echo "WARN: apply wrapper missing or not executable"
fi
echo "DO_NOT_RERUN_14J_AG_APPLY_WRAPPER=preserved"

if [ "$fail" -ne 0 ]; then
  echo "FAIL: Phase 14J-CG smoke failed"
  exit 1
fi

echo "PASS: Phase 14J-CG bounded runtime activation gate plan smoke passed"
