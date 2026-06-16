#!/usr/bin/env bash
set -euo pipefail

echo "=== Phase 14J-AO smoke: default-off worker registration UPDATE preserve-existing metadata wiring patch ==="

DOC="docs/phase-14j-ao-default-off-worker-registration-update-preserve-existing-metadata-wiring-patch.md"
DB="edge_queue.sqlite3"

fail=0

echo
echo "=== required artifacts ==="
for p in \
  "$DOC" \
  "docs/phase-14j-an-default-off-worker-registration-update-preserve-existing-metadata-wiring-plan.md" \
  "ops/smoke/check-phase-14j-an-default-off-worker-registration-update-preserve-existing-metadata-wiring-plan.sh" \
  "docs/phase-14j-am-default-off-worker-registration-insert-metadata-wiring-patch.md" \
  "ops/smoke/check-phase-14j-am-default-off-worker-registration-insert-metadata-wiring-patch.sh" \
  "docs/phase-14j-ak-default-off-worker-registration-metadata-helper-patch.md" \
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
python3 - <<'APC_AO_DOC_MARKERS'
from pathlib import Path

text = Path("docs/phase-14j-ao-default-off-worker-registration-update-preserve-existing-metadata-wiring-patch.md").read_text()

required = [
    "source code patch and smoke coverage",
    "allow worker-provided lane metadata",
    "enable `EDGE_PERSISTENT_LANE_WORKERS_ENABLED`",
    "call CT101",
    "call live model endpoints",
    "mutate job 23",
    "activate scheduler lane dispatch",
    "activate primary-worker filtering",
    "INSERT and UPDATE default metadata wiring are not scheduler activation.",
    "_phase14j_default_off_worker_registration_metadata()",
    "worker_role = COALESCE(worker_role, ?)",
    "worker_lane = COALESCE(worker_lane, ?)",
    "accepts_lane_jobs = COALESCE(accepts_lane_jobs, ?)",
    "capabilities = COALESCE(capabilities, ?)",
    "disabled = COALESCE(disabled, ?)",
    "current_running_jobs = COALESCE(current_running_jobs, ?)",
    "state = COALESCE(state, ?)",
    "computed_health = COALESCE(computed_health, ?)",
    "The UPDATE branch does not consume lane metadata from worker payloads.",
    "The UPDATE branch does not set `accepts_lane_jobs=1`.",
    "The UPDATE branch does not set a non-empty `worker_lane`.",
    "Phase 14J-AP: worker registration metadata wiring static validation and live-reload decision checkpoint, docs/smoke only",
]

missing = [item for item in required if item not in text]
if missing:
    raise SystemExit("FAIL: missing doc markers: " + ", ".join(missing))

print("PASS: documentation markers verified")
APC_AO_DOC_MARKERS

echo
echo "=== compile check without writing pycache ==="
python3 - <<'APC_AO_COMPILE'
from pathlib import Path
compile(Path("edge_controller.py").read_text(), "edge_controller.py", "exec")
print("PASS: edge_controller.py compiles via in-memory compile")
APC_AO_COMPILE

echo
echo "=== helper source and behavior verification ==="
python3 - <<'APC_AO_HELPER'
from pathlib import Path
import ast

path = Path("edge_controller.py")
text = path.read_text()
helper = "_phase14j_default_off_worker_registration_metadata"

if text.count(f"def {helper}(") != 1:
    raise SystemExit("FAIL: expected exactly one helper definition")

if text.count(f"{helper}(") != 3:
    raise SystemExit("FAIL: expected helper definition plus INSERT and UPDATE branch calls")

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
exec(compile(module, "ao_helper_only", "exec"), namespace)

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

print("PASS: helper returns exact default-off metadata")
APC_AO_HELPER

echo
echo "=== worker registration INSERT and UPDATE wiring verification ==="
python3 - <<'APC_AO_SOURCE'
from pathlib import Path
import re

text = Path("edge_controller.py").read_text()
helper = "_phase14j_default_off_worker_registration_metadata"

start = text.index("@app.post(\"/workers/heartbeat\")")
end = text.index("@app.get(\"/workers/registry\")", start)
window = text[start:end]

if "        if existing:" not in window or "        else:" not in window:
    raise SystemExit("FAIL: expected if existing / else registration structure missing")

update_branch, insert_branch = window.split("        else:", 1)

if f"registration_metadata = {helper}()" not in update_branch:
    raise SystemExit("FAIL: helper assignment missing from UPDATE branch")

if f"registration_metadata = {helper}()" not in insert_branch:
    raise SystemExit("FAIL: helper assignment missing from INSERT branch")

if update_branch.count(f"{helper}()") != 1:
    raise SystemExit("FAIL: expected exactly one helper call in UPDATE branch")

if insert_branch.count(f"{helper}()") != 1:
    raise SystemExit("FAIL: expected exactly one helper call in INSERT branch")

coalesce_lines = [
    "worker_role = COALESCE(worker_role, ?)",
    "worker_lane = COALESCE(worker_lane, ?)",
    "accepts_lane_jobs = COALESCE(accepts_lane_jobs, ?)",
    "capabilities = COALESCE(capabilities, ?)",
    "disabled = COALESCE(disabled, ?)",
    "current_running_jobs = COALESCE(current_running_jobs, ?)",
    "state = COALESCE(state, ?)",
    "computed_health = COALESCE(computed_health, ?)",
]

for line in coalesce_lines:
    if line not in update_branch:
        raise SystemExit(f"FAIL: UPDATE branch missing preserve-existing assignment: {line}")

metadata_keys = [
    "worker_role",
    "worker_lane",
    "accepts_lane_jobs",
    "capabilities",
    "disabled",
    "current_running_jobs",
    "state",
    "computed_health",
]

for key in metadata_keys:
    marker = f'registration_metadata["{key}"]'
    if marker not in update_branch:
        raise SystemExit(f"FAIL: UPDATE branch missing helper parameter {marker}")
    if marker not in insert_branch:
        raise SystemExit(f"FAIL: INSERT branch missing helper parameter {marker}")

for forbidden in [
    "payload.worker_role",
    "payload.worker_lane",
    "payload.accepts_lane_jobs",
    "payload.disabled",
    "payload.current_running_jobs",
    "payload.computed_health",
]:
    if forbidden in window:
        raise SystemExit(f"FAIL: worker payload lane metadata unexpectedly consumed: {forbidden}")

update_match = re.search(r"UPDATE workers\s*SET\s*(.*?)\s*WHERE worker_id = \?", update_branch, re.S)
if not update_match:
    raise SystemExit("FAIL: could not parse UPDATE block")

update_placeholder_count = update_match.group(1).count("?") + 1
if update_placeholder_count != 26:
    raise SystemExit(f"FAIL: expected 26 UPDATE placeholders including WHERE, found {update_placeholder_count}")

insert_match = re.search(r"INSERT INTO workers\s*\((.*?)\)\s*VALUES\s*\((.*?)\)", insert_branch, re.S)
if not insert_match:
    raise SystemExit("FAIL: could not parse INSERT block")

insert_columns = [c.strip() for c in insert_match.group(1).split(",") if c.strip()]
insert_placeholder_count = insert_match.group(2).count("?")

if len(insert_columns) != 29:
    raise SystemExit(f"FAIL: expected 29 INSERT columns, found {len(insert_columns)}")

if insert_placeholder_count != 29:
    raise SystemExit(f"FAIL: expected 29 INSERT placeholders, found {insert_placeholder_count}")

print("PASS: UPDATE preserve-existing wiring and AM INSERT wiring verified")
APC_AO_SOURCE

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
  echo "PASS: worker registry remains empty before live service reload"
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
python3 - <<'APC_AO_GATE'
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
APC_AO_GATE

echo
echo "=== static guard: AO smoke must not execute forbidden runtime actions ==="
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
  echo "PASS: Phase 14J-AO smoke complete"
else
  echo "FAIL: Phase 14J-AO smoke failed"
fi

exit "$fail"
