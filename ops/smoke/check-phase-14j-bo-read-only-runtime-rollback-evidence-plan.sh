#!/usr/bin/env bash
set -euo pipefail

echo "=== Phase 14J-BO smoke: read-only runtime rollback evidence plan ==="

DOC="docs/phase-14j-bo-read-only-runtime-rollback-evidence-plan.md"
SMOKE="ops/smoke/check-phase-14j-bo-read-only-runtime-rollback-evidence-plan.sh"
DB="edge_queue.sqlite3"
SERVICE="edge-queue-controller"

echo
echo "=== required files ==="
test -f "$DOC"
test -f "$SMOKE"
test -f "docs/phase-14j-bj-rollback-safety-docs-and-smoke-artifact.md"
test -f "ops/smoke/check-phase-14j-bj-rollback-safety-docs-and-smoke-artifact.sh"
test -f "docs/phase-14j-bk-runtime-activation-preflight-checklist-and-rollback-verification-plan.md"
test -f "ops/smoke/check-phase-14j-bk-runtime-activation-preflight-checklist-and-rollback-verification-plan.sh"
test -f "ops/smoke/check-phase-14j-bl-read-only-activation-surface-inspection-result-checkpoint.sh"
test -f "ops/smoke/check-phase-14j-bn-docs-smoke-only-activation-planning-decision-record.sh"
echo "PASS: required BO and prior rollback/preflight artifacts exist"

echo
echo "=== doc markers ==="
for marker in \
  "PHASE_14J_BO_READ_ONLY_RUNTIME_ROLLBACK_EVIDENCE_PLAN" \
  "MUTATION_SCOPE=docs_smoke_only_runtime_read_only_evidence" \
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
  "ACTIVATION_DECISION=still_blocked_pending_explicit_approval" \
  "EDGE_PERSISTENT_LANE_WORKERS_ENABLED=must_remain_absent_or_disabled" \
  "ROLLBACK_OBJECTIVE=return_to_primary_default_behavior" \
  "ROLLBACK_COMMAND_PATH=planned_not_executed" \
  "ROLLBACK_VERIFICATION_SMOKE=defined" \
  "SERVICE_RESTART_RELOAD_REQUIRED_FOR_ACTUAL_ROLLBACK=approval_required_later" \
  "NEXT_SAFE_PHASE=phase_14j_bp_read_only_activation_go_no_go_readiness_review" \
  "ACTIVATION_REQUIRES_EXPLICIT_USER_APPROVAL"
do
  grep -F "$marker" "$DOC" >/dev/null
  echo "PASS: doc marker found: $marker"
done

echo
echo "=== source activation surface markers ==="
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
test -f "$DB"
quick_check="$(sqlite3 "file:${DB}?mode=ro" 'PRAGMA quick_check;')"
printf 'quick_check=%s\n' "$quick_check"
test "$quick_check" = "ok"
echo "PASS: SQLite read-only quick_check ok"

echo
echo "=== worker registry canonical lane metadata columns ==="
cols="$(sqlite3 "file:${DB}?mode=ro" 'PRAGMA table_info(workers);' | awk -F'|' '{print $2}' | sort)"

for col in \
  worker_role \
  worker_lane \
  accepts_lane_jobs \
  capabilities \
  disabled \
  current_running_jobs \
  state \
  computed_health
do
  printf '%s\n' "$cols" | grep -Fx "$col" >/dev/null
  echo "PASS: canonical column present: $col"
done

if printf '%s\n' "$cols" | grep -Fx 'disabled_reason' >/dev/null; then
  echo "FAIL: disabled_reason is present but is non-canonical for Phase 14J lane metadata"
  exit 1
else
  echo "PASS: disabled_reason absent/non-canonical as expected"
fi

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
for marker in \
  "RUNTIME_ACTIVATION=not_performed" \
  "SERVICE_RESTART_RELOAD=not_performed" \
  "CT101_MODEL_JOB_MUTATION=not_performed" \
  "JOB_MUTATION=not_performed" \
  "LANE_WORKER_ENABLEMENT=not_performed" \
  "SCHEDULER_LANE_DISPATCH_ACTIVATION=not_performed" \
  "PRIMARY_WORKER_FILTERING_ACTIVATION=not_performed" \
  "ROUTER_MODEL_SELECTION_ACTIVATION=not_performed"
do
  grep -F "$marker" "$DOC" >/dev/null
  echo "PASS: no-runtime marker found: $marker"
done

echo
echo "PASS: Phase 14J-BO read-only runtime rollback evidence plan smoke passed"
