#!/usr/bin/env bash
set -euo pipefail

echo "=== Phase 14J-AQ smoke: controller service reload readiness plan ==="

DOC="docs/phase-14j-aq-controller-service-reload-readiness-plan.md"
DB="edge_queue.sqlite3"

fail=0

echo
echo "=== required artifacts ==="
for p in \
  "$DOC" \
  "docs/phase-14j-ap-worker-registration-metadata-wiring-static-validation-and-live-reload-decision-checkpoint.md" \
  "ops/smoke/check-phase-14j-ap-worker-registration-metadata-wiring-static-validation-and-live-reload-decision-checkpoint.sh" \
  "docs/phase-14j-ao-default-off-worker-registration-update-preserve-existing-metadata-wiring-patch.md" \
  "ops/smoke/check-phase-14j-ao-default-off-worker-registration-update-preserve-existing-metadata-wiring-patch.sh" \
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
python3 - <<'APC_AQ_DOC_MARKERS'
from pathlib import Path

text = Path("docs/phase-14j-aq-controller-service-reload-readiness-plan.md").read_text()

required = [
    "This phase is documentation and smoke only.",
    "restart or reload services",
    "call CT101",
    "call live model endpoints",
    "mutate job 23",
    "activate scheduler lane dispatch",
    "activate primary-worker filtering",
    "Reload readiness planning is not live reload.",
    "The future reload phase must require explicit approval",
    "No such command is run in Phase 14J-AQ.",
    "controller_service_reload_not_approved",
    "Phase 14J-AR: controller service reload preflight inspection, read-only only",
]

missing = [item for item in required if item not in text]
if missing:
    raise SystemExit("FAIL: missing doc markers: " + ", ".join(missing))

print("PASS: documentation markers verified")
APC_AQ_DOC_MARKERS

echo
echo "=== compile check without writing pycache ==="
python3 - <<'APC_AQ_COMPILE'
from pathlib import Path
compile(Path("edge_controller.py").read_text(), "edge_controller.py", "exec")
print("PASS: edge_controller.py compiles via in-memory compile")
APC_AQ_COMPILE

echo
echo "=== static source validation remains after AP/AO ==="
python3 - <<'APC_AQ_SOURCE'
from pathlib import Path
import ast
import re

text = Path("edge_controller.py").read_text()
helper = "_phase14j_default_off_worker_registration_metadata"

if text.count(f"def {helper}(") != 1:
    raise SystemExit("FAIL: expected exactly one helper definition")

if text.count(f"{helper}(") != 3:
    raise SystemExit("FAIL: expected helper definition plus INSERT and UPDATE branch calls")

tree = ast.parse(text)
func = next((n for n in tree.body if isinstance(n, ast.FunctionDef) and n.name == helper), None)
if func is None:
    raise SystemExit("FAIL: helper not found by AST")

module = ast.Module(body=[func], type_ignores=[])
ast.fix_missing_locations(module)
ns = {}
exec(compile(module, "aq_helper_only", "exec"), ns)

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

actual = ns[helper]()
if actual != expected:
    raise SystemExit(f"FAIL: helper returned unexpected defaults: {actual!r}")

start = text.index("@app.post(\"/workers/heartbeat\")")
end = text.index("@app.get(\"/workers/registry\")", start)
window = text[start:end]
update_branch, insert_branch = window.split("        else:", 1)

if update_branch.count(f"{helper}()") != 1:
    raise SystemExit("FAIL: expected exactly one UPDATE helper call")

if insert_branch.count(f"{helper}()") != 1:
    raise SystemExit("FAIL: expected exactly one INSERT helper call")

for line in [
    "worker_role = COALESCE(worker_role, ?)",
    "worker_lane = COALESCE(worker_lane, ?)",
    "accepts_lane_jobs = COALESCE(accepts_lane_jobs, ?)",
    "capabilities = COALESCE(capabilities, ?)",
    "disabled = COALESCE(disabled, ?)",
    "current_running_jobs = COALESCE(current_running_jobs, ?)",
    "state = COALESCE(state, ?)",
    "computed_health = COALESCE(computed_health, ?)",
]:
    if line not in update_branch:
        raise SystemExit(f"FAIL: UPDATE branch missing {line}")

insert_match = re.search(r"INSERT INTO workers\s*\((.*?)\)\s*VALUES\s*\((.*?)\)", insert_branch, re.S)
if not insert_match:
    raise SystemExit("FAIL: could not parse INSERT block")

if len([c.strip() for c in insert_match.group(1).split(",") if c.strip()]) != 29:
    raise SystemExit("FAIL: INSERT column count changed")

if insert_match.group(2).count("?") != 29:
    raise SystemExit("FAIL: INSERT placeholder count changed")

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

print("PASS: AP/AO static source validation still passes")
APC_AQ_SOURCE

echo
echo "=== source surface remains docs/smoke-only for AQ ==="
if git diff --name-only | grep -q '^edge_controller.py$'; then
  echo "FAIL: edge_controller.py changed during AQ docs/smoke-only phase"
  fail=1
else
  echo "PASS: edge_controller.py unchanged in AQ"
fi

echo
echo "=== service inspection only; no reload performed ==="
service_active="$(systemctl is-active edge-queue-controller 2>/dev/null || true)"
service_enabled="$(systemctl is-enabled edge-queue-controller 2>/dev/null || true)"
main_pid="$(systemctl show edge-queue-controller -p MainPID --value 2>/dev/null || true)"
echo "service_active=${service_active:-unknown}"
echo "service_enabled=${service_enabled:-unknown}"
echo "main_pid=${main_pid:-unknown}"
echo "PASS: service inspected only; no restart/reload performed"

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

echo "target_columns_present=$target_columns"
echo "lane_enabled_worker_count=$lane_enabled"

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
python3 - <<'APC_AQ_GATE'
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
APC_AQ_GATE

echo
echo "=== static guard: AQ smoke must not execute forbidden runtime actions ==="
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
  echo "PASS: Phase 14J-AQ smoke complete"
else
  echo "FAIL: Phase 14J-AQ smoke failed"
fi

exit "$fail"
