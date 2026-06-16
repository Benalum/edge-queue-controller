#!/usr/bin/env bash
set -euo pipefail

echo "=== Phase 14J-BC smoke: synthetic fallback and rollback smoke design ==="

DOC="docs/phase-14j-bc-synthetic-fallback-and-rollback-smoke-design.md"
DB="edge_queue.sqlite3"
fail=0

echo
echo "=== required artifacts ==="
for p in \
  "$DOC" \
  "docs/phase-14j-bb-no-lane-fallback-and-rollback-evidence-checkpoint.md" \
  "ops/smoke/check-phase-14j-bb-no-lane-fallback-and-rollback-evidence-checkpoint.sh" \
  "docs/phase-14j-az-no-lane-fallback-and-rollback-plan.md" \
  "docs/phase-14j-ay-lane-worker-activation-evidence-result-checkpoint.md" \
  "docs/phase-14j-ao-default-off-worker-registration-update-preserve-existing-metadata-wiring-patch.md" \
  "ops/db/default-off-worker-registry-lane-metadata.sql" \
  "$DB"
do
  if [ -e "$p" ]; then
    echo "PASS: exists $p"
  else
    echo "FAIL: missing $p"
    fail=1
  fi
done

echo
echo "=== documentation markers ==="
python3 - <<'APC_BC_DOC_CHECK'
from pathlib import Path

text = Path("docs/phase-14j-bc-synthetic-fallback-and-rollback-smoke-design.md").read_text()

required = [
    "This phase is documentation and smoke only.",
    "disabled gate behavior remains equivalent to current behavior",
    "no-lane jobs preserve the primary/default path",
    "Required synthetic smoke cases",
    "disabled_equivalence",
    "no_lane_primary",
    "lane_match",
    "lane_missing_with_fallback",
    "lane_missing_no_fallback",
    "disabled_rollback",
    "The in-process enabled cases must only set environment inside a temporary Python process or subshell.",
    "Rollback smoke design",
    "`EDGE_PERSISTENT_LANE_WORKERS_ENABLED` is absent or false",
    "CT101 is not called",
    "no live model endpoint is called",
    "no production job row is changed",
    "Synthetic smoke design is not runtime activation.",
    "In-process helper testing is not service activation.",
    "Rollback design is not rollback execution.",
    "`persistent_lane_workers_not_active`",
    "`scheduler_lane_dispatch_not_active`",
    "`rollback_smoke_pending`",
    "`synthetic_enabled_lane_smoke_pending`",
    "`activation_approval_required`",
    "Phase 14J-BD: synthetic fallback and rollback smoke artifact, smoke-only/no runtime activation",
]

missing = [item for item in required if item not in text]
if missing:
    raise SystemExit("FAIL: missing doc markers: " + ", ".join(missing))

print("PASS: documentation markers verified")
APC_BC_DOC_CHECK

echo
echo "=== compile check ==="
python3 - <<'APC_BC_COMPILE'
from pathlib import Path
compile(Path("edge_controller.py").read_text(), "edge_controller.py", "exec")
print("PASS: edge_controller.py compiles via in-memory compile")
APC_BC_COMPILE

echo
echo "=== source synthetic smoke prerequisites ==="
python3 - <<'APC_BC_SOURCE'
from pathlib import Path

text = Path("edge_controller.py").read_text()

required = [
    "def _phase14j_lane_workers_enabled(",
    "def _phase14j_job_lane_metadata(",
    "def _phase14j_worker_lane_metadata(",
    "def _phase14j_worker_eligible_for_job(",
    "def _phase14j_filter_workers_for_lane(",
    "if not _phase14j_lane_workers_enabled():",
    "return list(workers)",
    "allow_primary_fallback",
    "primary_fallback_not_allowed",
    "lane_mismatch",
    "capacity_reached",
    "phase14j_lane_scheduler_gate_enabled = _phase14j_lane_workers_enabled()",
    "if phase14j_lane_scheduler_gate_enabled:",
]

missing = [item for item in required if item not in text]
if missing:
    raise SystemExit("FAIL: missing synthetic smoke prerequisite markers: " + ", ".join(missing))

for forbidden in [
    "payload.worker_role",
    "payload.worker_lane",
    "payload.accepts_lane_jobs",
    "payload.disabled",
    "payload.current_running_jobs",
    "payload.computed_health",
]:
    if forbidden in text:
        raise SystemExit(f"FAIL: worker payload lane metadata unexpectedly consumed: {forbidden}")

print("PASS: synthetic smoke prerequisite markers remain present and worker payload lane metadata remains blocked")
APC_BC_SOURCE

echo
echo "=== source remains docs/smoke only for BC ==="
if git diff --name-only | grep -q '^edge_controller.py$'; then
  echo "FAIL: edge_controller.py changed during BC"
  fail=1
else
  echo "PASS: edge_controller.py unchanged in BC"
fi

echo
echo "=== default-off DB state ==="
sqlite3 "file:$PWD/$DB?mode=ro" "PRAGMA quick_check;" || fail=1

worker_count="$(sqlite3 "file:$PWD/$DB?mode=ro" "SELECT COUNT(*) FROM workers;")"
target_columns="$(sqlite3 "file:$PWD/$DB?mode=ro" "
SELECT COUNT(*)
FROM pragma_table_info('workers')
WHERE name IN (
  'worker_role',
  'worker_lane',
  'accepts_lane_jobs',
  'capabilities',
  'disabled',
  'current_running_jobs',
  'state',
  'computed_health'
);
")"
lane_enabled="$(sqlite3 "file:$PWD/$DB?mode=ro" "SELECT COUNT(*) FROM workers WHERE COALESCE(CAST(accepts_lane_jobs AS INTEGER), 0) != 0;")"
non_default_lane="$(sqlite3 "file:$PWD/$DB?mode=ro" "SELECT COUNT(*) FROM workers WHERE COALESCE(worker_lane, '') != '';" )"
non_primary_role="$(sqlite3 "file:$PWD/$DB?mode=ro" "SELECT COUNT(*) FROM workers WHERE COALESCE(worker_role, 'primary') != 'primary';" )"

echo "worker_count=$worker_count"
echo "target_columns_present=$target_columns"
echo "lane_enabled_worker_count=$lane_enabled"
echo "non_default_worker_lane_count=$non_default_lane"
echo "non_primary_worker_role_count=$non_primary_role"

if [ "$target_columns" = "8" ]; then echo "PASS: target metadata columns present"; else echo "FAIL: target metadata column count not 8"; fail=1; fi
if [ "$lane_enabled" = "0" ]; then echo "PASS: no lane-enabled workers"; else echo "FAIL: lane-enabled workers detected"; fail=1; fi
if [ "$non_default_lane" = "0" ]; then echo "PASS: no non-empty worker_lane"; else echo "FAIL: non-empty worker_lane detected"; fail=1; fi
if [ "$non_primary_role" = "0" ]; then echo "PASS: no non-primary worker_role"; else echo "FAIL: non-primary worker_role detected"; fail=1; fi

echo
echo "=== persistent lane worker flag remains disabled ==="
echo "shell_EDGE_PERSISTENT_LANE_WORKERS_ENABLED=${EDGE_PERSISTENT_LANE_WORKERS_ENABLED-<unset>}"

case "${EDGE_PERSISTENT_LANE_WORKERS_ENABLED-}" in
  1|true|TRUE)
    echo "FAIL: shell persistent lane workers flag appears enabled"
    fail=1
    ;;
  *)
    echo "PASS: shell persistent lane workers flag absent/disabled"
    ;;
esac

service_env="$(systemctl show edge-queue-controller -p Environment --value 2>/dev/null || true)"
printf '%s\n' "$service_env" | tr ' ' '\n' | grep -q '^EDGE_PERSISTENT_LANE_WORKERS_ENABLED=\(1\|true\|TRUE\)$' \
  && { echo "FAIL: service persistent lane workers flag appears enabled"; fail=1; } \
  || echo "PASS: service persistent lane workers flag absent/disabled"

echo
echo "=== controller service read-only health check ==="
service_active="$(systemctl is-active edge-queue-controller 2>/dev/null || true)"
echo "service_active=${service_active:-unknown}"

if [ "$service_active" = "active" ]; then
  echo "PASS: edge-queue-controller active"
else
  echo "FAIL: edge-queue-controller not active"
  fail=1
fi

health_code="$(
  curl -sS --max-time 5 -o /tmp/phase14j-bc-local-health.json \
    -w "%{http_code}" \
    http://127.0.0.1:7070/system/local-health 2>/tmp/phase14j-bc-local-health.err || true
)"
echo "local_health_http_code=${health_code:-curl_failed}"

if [ "$health_code" = "200" ]; then
  echo "PASS: controller-only local health returned 200"
else
  echo "FAIL: controller-only local health did not return 200"
  fail=1
fi

echo
echo "=== static guard: BC smoke must not execute forbidden runtime actions ==="
forbidden_runtime_lines="$(grep -nE '^[[:space:]]*(sudo[[:space:]]+systemctl[[:space:]]+(restart|reload)|systemctl[[:space:]]+(restart|reload)|pct[[:space:]]+exec|ssh[[:space:]]+root@|curl[[:space:]].*127\.0\.0\.1:(11434|8088))' "$0" || true)"
if [ -n "$forbidden_runtime_lines" ]; then
  echo "FAIL: BC smoke contains executable forbidden runtime lines"
  echo "$forbidden_runtime_lines"
  fail=1
else
  echo "PASS: BC smoke contains no executable forbidden runtime lines"
fi

echo
if [ "$fail" = "0" ]; then
  echo "PASS: Phase 14J-BC smoke complete"
else
  echo "FAIL: Phase 14J-BC smoke failed"
fi

exit "$fail"
