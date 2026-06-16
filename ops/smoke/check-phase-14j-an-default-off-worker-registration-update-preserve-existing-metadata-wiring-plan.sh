#!/usr/bin/env bash
set -euo pipefail

echo "=== Phase 14J-AN smoke: default-off worker registration UPDATE preserve-existing metadata wiring plan ==="

DOC="docs/phase-14j-an-default-off-worker-registration-update-preserve-existing-metadata-wiring-plan.md"
DB="edge_queue.sqlite3"

fail=0

echo
echo "=== required artifacts ==="
for p in \
  "$DOC" \
  "docs/phase-14j-am-default-off-worker-registration-insert-metadata-wiring-patch.md" \
  "ops/smoke/check-phase-14j-am-default-off-worker-registration-insert-metadata-wiring-patch.sh" \
  "docs/phase-14j-al-default-off-worker-registration-insert-metadata-wiring-plan.md" \
  "docs/phase-14j-ak-default-off-worker-registration-metadata-helper-patch.md" \
  "docs/phase-14j-aj-default-off-worker-registration-metadata-write-patch-plan.md" \
  "docs/phase-14j-ai-default-off-worker-registration-metadata-write-contract.md" \
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
python3 - <<'APC_AN_DOC_MARKERS'
from pathlib import Path

text = Path("docs/phase-14j-an-default-off-worker-registration-update-preserve-existing-metadata-wiring-plan.md").read_text()

required = [
    "This phase is documentation and smoke only.",
    "change `edge_controller.py`",
    "change `UPDATE workers`",
    "wire new UPDATE metadata writes",
    "enable `EDGE_PERSISTENT_LANE_WORKERS_ENABLED`",
    "call CT101",
    "call live model endpoints",
    "mutate job 23",
    "activate scheduler lane dispatch",
    "activate primary-worker filtering",
    "UPDATE wiring planning is not runtime activation.",
    "The existing-worker UPDATE path remains legacy/unwired.",
    "use default-off fallback values only when existing metadata is NULL",
    "`worker_role='primary'`",
    "`worker_lane=''`",
    "`accepts_lane_jobs=0`",
    "`capabilities='[]'`",
    "`disabled=0`",
    "`current_running_jobs=0`",
    "`state='available'`",
    "`computed_health=''`",
    "worker_role = COALESCE(worker_role, ?)",
    "worker_lane = COALESCE(worker_lane, ?)",
    "accepts_lane_jobs = COALESCE(accepts_lane_jobs, ?)",
    "Phase 14J-AO: default-off worker registration UPDATE preserve-existing metadata wiring patch, code/smoke, no runtime activation",
]

missing = [item for item in required if item not in text]
if missing:
    raise SystemExit("FAIL: missing doc markers: " + ", ".join(missing))

print("PASS: documentation markers verified")
APC_AN_DOC_MARKERS

echo
echo "=== compile check without writing pycache ==="
python3 - <<'APC_AN_COMPILE'
from pathlib import Path
compile(Path("edge_controller.py").read_text(), "edge_controller.py", "exec")
print("PASS: edge_controller.py compiles via in-memory compile")
APC_AN_COMPILE

echo
echo "=== AM INSERT wiring remains present and UPDATE remains legacy/unwired ==="
python3 - <<'APC_AN_SOURCE'
from pathlib import Path
import re

text = Path("edge_controller.py").read_text()
helper = "_phase14j_default_off_worker_registration_metadata"

if text.count(f"def {helper}(") != 1:
    raise SystemExit("FAIL: expected exactly one helper definition")

if text.count(f"{helper}(") != 2:
    raise SystemExit("FAIL: expected helper definition plus one INSERT branch call after AM")

start = text.index("@app.post(\"/workers/heartbeat\")")
end = text.index("@app.get(\"/workers/registry\")", start)
window = text[start:end]

if "        if existing:" not in window or "        else:" not in window:
    raise SystemExit("FAIL: expected if existing / else registration structure missing")

before_else, insert_branch = window.split("        else:", 1)

if helper in before_else:
    raise SystemExit("FAIL: helper appears in UPDATE path before AO")

if f"registration_metadata = {helper}()" not in insert_branch:
    raise SystemExit("FAIL: helper assignment missing from INSERT branch")

if "UPDATE workers" not in before_else:
    raise SystemExit("FAIL: UPDATE branch marker missing")

for forbidden in [
    "worker_role = COALESCE(worker_role",
    "worker_lane = COALESCE(worker_lane",
    "accepts_lane_jobs = COALESCE(accepts_lane_jobs",
    "capabilities = COALESCE(capabilities",
    "disabled = COALESCE(disabled",
    "current_running_jobs = COALESCE(current_running_jobs",
    "state = COALESCE(state",
    "computed_health = COALESCE(computed_health",
]:
    if forbidden in before_else:
        raise SystemExit(f"FAIL: UPDATE branch already contains future preserve-existing wiring: {forbidden}")

required_columns = [
    "worker_role",
    "worker_lane",
    "accepts_lane_jobs",
    "capabilities",
    "disabled",
    "current_running_jobs",
    "state",
    "computed_health",
]

for column in required_columns:
    if column not in insert_branch:
        raise SystemExit(f"FAIL: INSERT branch missing metadata column {column}")

for key in required_columns:
    marker = f'registration_metadata["{key}"]'
    if marker not in insert_branch:
        raise SystemExit(f"FAIL: INSERT branch missing helper parameter {marker}")

match = re.search(r"INSERT INTO workers\s*\((.*?)\)\s*VALUES\s*\((.*?)\)", insert_branch, re.S)
if not match:
    raise SystemExit("FAIL: could not parse INSERT block")

columns = [c.strip() for c in match.group(1).split(",") if c.strip()]
placeholder_count = match.group(2).count("?")

if len(columns) != 29:
    raise SystemExit(f"FAIL: expected 29 INSERT columns, found {len(columns)}")

if placeholder_count != 29:
    raise SystemExit(f"FAIL: expected 29 INSERT placeholders, found {placeholder_count}")

print("PASS: AM INSERT wiring remains present and UPDATE remains legacy/unwired")
APC_AN_SOURCE

echo
echo "=== source surface remains docs/smoke-only for AN ==="
if git diff --name-only | grep -q '^edge_controller.py$'; then
  echo "FAIL: edge_controller.py changed during AN docs/smoke-only phase"
  fail=1
else
  echo "PASS: edge_controller.py unchanged in AN"
fi

echo
echo "=== prior documentation artifacts remain present ==="
python3 - <<'APC_AN_PRIOR_DOCS'
from pathlib import Path

checks = {
    "docs/phase-14j-am-default-off-worker-registration-insert-metadata-wiring-patch.md": [
        "Phase 14J-AM wires",
        "INSERT default metadata wiring is not scheduler activation.",
    ],
    "docs/phase-14j-al-default-off-worker-registration-insert-metadata-wiring-plan.md": [
        "This phase is documentation and smoke only.",
        "Phase 14J-AM: default-off worker registration insert metadata wiring patch",
    ],
    "docs/phase-14j-ak-default-off-worker-registration-metadata-helper-patch.md": [
        "_phase14j_default_off_worker_registration_metadata()",
        "Helper presence is not runtime activation.",
    ],
    "docs/phase-14j-aj-default-off-worker-registration-metadata-write-patch-plan.md": [
        "This phase is documentation and smoke only.",
        "Future patch goal",
    ],
    "docs/phase-14j-ai-default-off-worker-registration-metadata-write-contract.md": [
        "Schema presence is not runtime activation.",
        "Preserve `accepts_lane_jobs=0`",
    ],
}

for filename, markers in checks.items():
    path = Path(filename)
    if not path.exists():
        raise SystemExit(f"FAIL: missing prior doc {filename}")
    text = path.read_text()
    missing = [m for m in markers if m not in text]
    if missing:
        raise SystemExit(f"FAIL: {filename} missing markers: {missing}")

print("PASS: prior AI/AJ/AK/AL/AM documentation artifacts remain present")
APC_AN_PRIOR_DOCS

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
python3 - <<'APC_AN_GATE'
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
APC_AN_GATE

echo
echo "=== static guard: AN smoke must not execute forbidden runtime actions ==="
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
  echo "PASS: Phase 14J-AN smoke complete"
else
  echo "FAIL: Phase 14J-AN smoke failed"
fi

exit "$fail"
