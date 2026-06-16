#!/usr/bin/env bash
set -euo pipefail

echo "=== Phase 14J-AL smoke: default-off worker registration insert metadata wiring plan ==="

DOC="docs/phase-14j-al-default-off-worker-registration-insert-metadata-wiring-plan.md"
DB="edge_queue.sqlite3"

fail=0

echo
echo "=== required artifacts ==="
for p in \
  "$DOC" \
  "docs/phase-14j-ak-default-off-worker-registration-metadata-helper-patch.md" \
  "ops/smoke/check-phase-14j-ak-default-off-worker-registration-metadata-helper-patch.sh" \
  "docs/phase-14j-aj-default-off-worker-registration-metadata-write-patch-plan.md" \
  "ops/smoke/check-phase-14j-aj-default-off-worker-registration-metadata-write-patch-plan.sh" \
  "docs/phase-14j-ai-default-off-worker-registration-metadata-write-contract.md" \
  "ops/smoke/check-phase-14j-ai-default-off-worker-registration-metadata-write-contract.sh" \
  "docs/phase-14j-ah-read-only-lane-worker-reentry-inspection-planning.md" \
  "ops/smoke/check-phase-14j-ah-read-only-lane-worker-reentry-inspection-planning.sh" \
  "docs/phase-14j-ag-guarded-default-off-worker-lane-metadata-schema-apply.md" \
  "ops/smoke/check-phase-14j-ag-guarded-default-off-worker-lane-metadata-schema-apply.sh" \
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
python3 - <<'APC_AL_DOC_MARKERS'
from pathlib import Path

text = Path("docs/phase-14j-al-default-off-worker-registration-insert-metadata-wiring-plan.md").read_text()

required = [
    "This phase is documentation and smoke only.",
    "Schema presence is not runtime activation. Helper presence is not runtime activation. Insert wiring planning is not runtime activation.",
    "change `edge_controller.py`",
    "wire the helper into worker registration runtime writes",
    "change `/workers/heartbeat`",
    "change `INSERT INTO workers`",
    "change `UPDATE workers`",
    "enable `EDGE_PERSISTENT_LANE_WORKERS_ENABLED`",
    "call CT101",
    "call live model endpoints",
    "mutate job 23",
    "activate scheduler lane dispatch",
    "activate primary-worker filtering",
    "_phase14j_default_off_worker_registration_metadata()",
    "The helper is intentionally unwired.",
    "modify only the new-worker INSERT path",
    "It should not modify UPDATE behavior in the same phase.",
    "`worker_role`",
    "`worker_lane`",
    "`accepts_lane_jobs`",
    "`capabilities`",
    "`disabled`",
    "`current_running_jobs`",
    "`state`",
    "`computed_health`",
    "keep `worker_lane=''`",
    "keep `accepts_lane_jobs=0`",
    "keep `worker_role='primary'`",
    "helper is called by the INSERT branch only",
    "helper is not called by the UPDATE branch",
    "Phase 14J-AM: default-off worker registration insert metadata wiring patch, code/smoke, no runtime activation",
]

missing = [item for item in required if item not in text]
if missing:
    raise SystemExit("FAIL: missing doc markers: " + ", ".join(missing))

print("PASS: documentation markers verified")
APC_AL_DOC_MARKERS

echo
echo "=== compile check without writing pycache ==="
python3 - <<'APC_AL_COMPILE'
from pathlib import Path
compile(Path("edge_controller.py").read_text(), "edge_controller.py", "exec")
print("PASS: edge_controller.py compiles via in-memory compile")
APC_AL_COMPILE

echo
echo "=== AK helper still exists and remains unwired ==="
python3 - <<'APC_AL_HELPER'
from pathlib import Path
import ast

text = Path("edge_controller.py").read_text()
helper = "_phase14j_default_off_worker_registration_metadata"

if text.count(f"def {helper}(") != 1:
    raise SystemExit("FAIL: expected exactly one AK helper definition")

if text.count(f"{helper}(") != 1:
    raise SystemExit("FAIL: helper should still be unwired before AM")

tree = ast.parse(text)
func = None
for node in tree.body:
    if isinstance(node, ast.FunctionDef) and node.name == helper:
        func = node
        break

if func is None:
    raise SystemExit("FAIL: helper not found by AST")

module = ast.Module(body=[func], type_ignores=[])
ast.fix_missing_locations(module)
namespace = {}
exec(compile(module, "ak_helper_only", "exec"), namespace)

expected = {
    "worker_role": "primary",
    "worker_lane": "",
    "accepts_lane_jobs": 0,
    "capabilities": "[]",
    "disabled": 0,
    "current_running_jobs": 0,
    "state": "available",
    "computed_health": "",
}

actual = namespace[helper]()
if actual != expected:
    raise SystemExit(f"FAIL: helper returned unexpected defaults: {actual!r}")

print("PASS: AK helper remains pure, exact, and unwired")
APC_AL_HELPER

echo
echo "=== worker registration path remains unchanged in docs/smoke-only AL ==="
python3 - <<'APC_AL_REGISTRATION'
from pathlib import Path

text = Path("edge_controller.py").read_text()

start = text.index("@app.post(\"/workers/heartbeat\")")
end = text.index("@app.get(\"/workers/registry\")", start)
window = text[start:end]

for forbidden in [
    "_phase14j_default_off_worker_registration_metadata",
    "worker_role",
    "worker_lane",
    "accepts_lane_jobs",
    "current_running_jobs",
]:
    if forbidden in window:
        raise SystemExit(f"FAIL: worker heartbeat runtime path unexpectedly contains {forbidden}")

required = [
    "INSERT INTO workers (",
    "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
    "UPDATE workers",
    "capabilities_json",
    "payload.capabilities",
]

missing = [item for item in required if item not in window]
if missing:
    raise SystemExit("FAIL: missing expected legacy registration markers: " + ", ".join(missing))

print("PASS: /workers/heartbeat registration path remains legacy/unwired")
APC_AL_REGISTRATION

echo
echo "=== source surface remains docs/smoke-only for AL ==="
if git diff --name-only | grep -q '^edge_controller.py$'; then
  echo "FAIL: edge_controller.py changed during AL docs/smoke-only phase"
  fail=1
else
  echo "PASS: edge_controller.py unchanged in AL"
fi

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
echo "=== read-only SQLite state remains default-off ==="
sqlite3 "file:$PWD/$DB?mode=ro" "PRAGMA quick_check;"

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
lane_enabled="$(sqlite3 "file:$PWD/$DB?mode=ro" "SELECT COUNT(*) FROM workers WHERE COALESCE(accepts_lane_jobs, 0) != 0;")"

echo "worker_count=$worker_count"
echo "target_columns_present=$target_columns"
echo "lane_enabled_worker_count=$lane_enabled"

if [ "$worker_count" = "0" ]; then
  echo "PASS: worker registry remains empty"
else
  echo "FAIL: unexpected worker rows present"
  fail=1
fi

if [ "$target_columns" = "8" ]; then
  echo "PASS: target metadata columns remain present"
else
  echo "FAIL: target metadata columns missing"
  fail=1
fi

if [ "$lane_enabled" = "0" ]; then
  echo "PASS: no lane-enabled workers"
else
  echo "FAIL: lane-enabled workers detected"
  fail=1
fi

echo
echo "=== scheduler lane gate remains default-off ==="
python3 - <<'APC_AL_GATE'
from pathlib import Path

text = Path("edge_controller.py").read_text()

required = [
    "phase14j_lane_scheduler_gate_enabled = _phase14j_lane_workers_enabled()",
    "if phase14j_lane_scheduler_gate_enabled:",
    "_phase14j_filter_workers_for_lane(workers, job)",
    "return str(value).strip().lower() in (\"1\", \"true\", \"yes\", \"on\")",
]

missing = [item for item in required if item not in text]
if missing:
    raise SystemExit("FAIL: missing scheduler gate markers: " + ", ".join(missing))

print("PASS: scheduler lane gate markers remain default-off")
APC_AL_GATE

echo
echo "=== static guard: AL smoke must not execute forbidden runtime actions ==="
forbidden_runtime_lines="$(grep -nE '^[[:space:]]*(systemctl[[:space:]]+(restart|reload)|pct[[:space:]]+exec|ssh[[:space:]]+root@|curl[[:space:]].*127\.0\.0\.1:(11434|8088))' "$0" || true)"
if [ -n "$forbidden_runtime_lines" ]; then
  echo "FAIL: smoke contains executable forbidden runtime lines"
  echo "$forbidden_runtime_lines"
  fail=1
else
  echo "PASS: smoke contains no executable forbidden runtime lines"
fi

echo
if [ "$fail" = "0" ]; then
  echo "PASS: Phase 14J-AL smoke complete"
else
  echo "FAIL: Phase 14J-AL smoke failed"
fi

exit "$fail"
