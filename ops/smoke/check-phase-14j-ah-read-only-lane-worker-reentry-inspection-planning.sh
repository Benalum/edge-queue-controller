#!/usr/bin/env bash
set -euo pipefail

echo "=== Phase 14J-AH smoke: read-only lane-worker re-entry inspection/planning ==="

DOC="docs/phase-14j-ah-read-only-lane-worker-reentry-inspection-planning.md"
DB="edge_queue.sqlite3"

fail=0

echo
echo "=== required artifacts ==="
for p in \
  "$DOC" \
  "docs/phase-14j-ag-guarded-default-off-worker-lane-metadata-schema-apply.md" \
  "ops/smoke/check-phase-14j-ag-guarded-default-off-worker-lane-metadata-schema-apply.sh" \
  "ops/db/default-off-worker-registry-lane-metadata.sql" \
  "ops/db/apply-default-off-worker-registry-lane-metadata.sh" \
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
echo "=== documentation safety markers ==="
python3 - <<'PY'
from pathlib import Path

doc = Path("docs/phase-14j-ah-read-only-lane-worker-reentry-inspection-planning.md")
text = doc.read_text()

required = [
    "This phase is documentation and smoke only.",
    "Schema presence is not runtime activation.",
    "rerun `ops/db/apply-default-off-worker-registry-lane-metadata.sh`",
    "enable `EDGE_PERSISTENT_LANE_WORKERS_ENABLED`",
    "call CT101",
    "call live model endpoints",
    "mutate job 23",
    "activate scheduler lane dispatch",
    "activate primary-worker filtering",
    "add runtime lane metadata writes",
    "worker_count=0",
    "target_columns_present=8",
    "lane_enabled_worker_count=0",
    "registration_default_off_write_contract_not_implemented",
    "Phase 14J-AI: default-off worker registration metadata write contract, docs/smoke only",
]

missing = [item for item in required if item not in text]
if missing:
    raise SystemExit("FAIL: missing doc markers: " + ", ".join(missing))

print("PASS: documentation markers verified")
PY

echo
echo "=== compile check without writing pycache ==="
python3 - <<'PY'
from pathlib import Path
compile(Path("edge_controller.py").read_text(), "edge_controller.py", "exec")
print("PASS: edge_controller.py compiles via in-memory compile")
PY

echo
echo "=== persistent lane worker flag remains disabled ==="
echo "shell_EDGE_PERSISTENT_LANE_WORKERS_ENABLED=${EDGE_PERSISTENT_LANE_WORKERS_ENABLED-<unset>}"
if [ "${EDGE_PERSISTENT_LANE_WORKERS_ENABLED-}" = "1" ] || [ "${EDGE_PERSISTENT_LANE_WORKERS_ENABLED-}" = "true" ] || [ "${EDGE_PERSISTENT_LANE_WORKERS_ENABLED-}" = "TRUE" ]; then
  echo "FAIL: shell persistent lane workers flag appears enabled"
  fail=1
else
  echo "PASS: shell persistent lane workers flag absent/disabled"
fi

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
echo "=== code surface remains gated/default-off ==="
python3 - <<'PY'
from pathlib import Path

text = Path("edge_controller.py").read_text()

required = [
    "phase14j_lane_scheduler_gate_enabled = _phase14j_lane_workers_enabled()",
    "if phase14j_lane_scheduler_gate_enabled:",
    "_phase14j_worker_lane_metadata",
    "Phase 14J-N disabled lane filter runtime call skeleton",
]

missing = [item for item in required if item not in text]
if missing:
    raise SystemExit("FAIL: missing gated/default-off lane scheduler markers: " + ", ".join(missing))

if "EDGE_PERSISTENT_LANE_WORKERS_ENABLED" not in text:
    raise SystemExit("FAIL: missing persistent lane worker env gate marker")

print("PASS: gated/default-off lane scheduler markers remain present")
PY

echo
echo "=== static guard: this AH smoke must not execute forbidden runtime actions ==="
python3 - <<'AH_STATIC_GUARD_PY'
from pathlib import Path
import re

script = Path("ops/smoke/check-phase-14j-ah-read-only-lane-worker-reentry-inspection-planning.sh").read_text()
bad_lines = []

patterns = [
    re.compile(r"^\s*systemctl\s+(restart|reload)\b"),
    re.compile(r"^\s*pct\s+exec\b"),
    re.compile(r"^\s*ssh\s+root@"),
    re.compile(r"^\s*curl\b.*127\.0\.0\.1:11434"),
    re.compile(r"^\s*curl\b.*127\.0\.1:8088"),
    re.compile(r"^\s*sqlite3\b.*\b(UPDATE|DELETE)\s+jobs\b", re.IGNORECASE),
]

for line_no, line in enumerate(script.splitlines(), 1):
    stripped = line.strip()
    if not stripped or stripped.startswith("#"):
        continue
    for pattern in patterns:
        if pattern.search(line):
            bad_lines.append(f"{line_no}:{line}")

if bad_lines:
    raise SystemExit("FAIL: AH smoke contains executable forbidden runtime lines: " + " | ".join(bad_lines))

print("PASS: AH smoke contains no executable forbidden runtime action lines")
AH_STATIC_GUARD_PY

echo
if [ "$fail" = "0" ]; then
  echo "PASS: Phase 14J-AH smoke complete"
else
  echo "FAIL: Phase 14J-AH smoke failed"
fi

exit "$fail"
