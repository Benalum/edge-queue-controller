#!/usr/bin/env bash
set -euo pipefail

echo "=== Phase 14J-AI smoke: default-off worker registration metadata write contract ==="

DOC="docs/phase-14j-ai-default-off-worker-registration-metadata-write-contract.md"
DB="edge_queue.sqlite3"

fail=0

echo
echo "=== required artifacts ==="
for p in \
  "$DOC" \
  "docs/phase-14j-ah-read-only-lane-worker-reentry-inspection-planning.md" \
  "ops/smoke/check-phase-14j-ah-read-only-lane-worker-reentry-inspection-planning.sh" \
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
echo "=== documentation contract markers ==="
python3 - <<'APC_PY_DOC_MARKERS'
from pathlib import Path

text = Path("docs/phase-14j-ai-default-off-worker-registration-metadata-write-contract.md").read_text()

required = [
    "This phase is documentation and smoke only.",
    "Schema presence is not runtime activation.",
    "change `edge_controller.py`",
    "enable `EDGE_PERSISTENT_LANE_WORKERS_ENABLED`",
    "call CT101",
    "call live model endpoints",
    "mutate job 23",
    "activate scheduler lane dispatch",
    "activate primary-worker filtering",
    "add runtime lane metadata writes",
    "change worker registration runtime behavior",
    "worker_count=0",
    "target_columns_present=8",
    "lane_enabled_worker_count=0",
    "`worker_role`",
    "`worker_lane`",
    "`accepts_lane_jobs`",
    "`capabilities`",
    "`disabled`",
    "`current_running_jobs`",
    "`state`",
    "`computed_health`",
    "Keep registration default-off.",
    "Do not allow a worker to become lane-enabled just by registering.",
    "Preserve `accepts_lane_jobs=0`",
    "Preserve `worker_lane=''`",
    "Phase 14J-AJ: default-off worker registration metadata write patch plan, docs/smoke only",
]

missing = [item for item in required if item not in text]
if missing:
    raise SystemExit("FAIL: missing doc markers: " + ", ".join(missing))

print("PASS: documentation contract markers verified")
APC_PY_DOC_MARKERS

echo
echo "=== compile check without writing pycache ==="
python3 - <<'APC_PY_COMPILE'
from pathlib import Path
compile(Path("edge_controller.py").read_text(), "edge_controller.py", "exec")
print("PASS: edge_controller.py compiles via in-memory compile")
APC_PY_COMPILE

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
echo "=== source surface remains unchanged for docs/smoke-only phase ==="
if git diff --name-only | grep -q '^edge_controller.py$'; then
  echo "FAIL: edge_controller.py changed during docs/smoke-only phase"
  fail=1
else
  echo "PASS: edge_controller.py unchanged"
fi

echo
echo "=== registration surface markers still exist for future contract ==="
python3 - <<'APC_PY_SOURCE_MARKERS'
from pathlib import Path

text = Path("edge_controller.py").read_text()

required = [
    "INSERT INTO workers",
    "UPDATE workers",
    "capabilities_json",
    "max_concurrent_jobs",
    "SELECT * FROM workers",
    "phase14j_lane_scheduler_gate_enabled = _phase14j_lane_workers_enabled()",
    "_phase14j_worker_lane_metadata",
]

missing = [item for item in required if item not in text]
if missing:
    raise SystemExit("FAIL: missing source markers: " + ", ".join(missing))

print("PASS: registration and gated lane markers remain present")
APC_PY_SOURCE_MARKERS

echo
echo "=== static guard: AI smoke must not execute forbidden runtime actions ==="
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
  echo "PASS: Phase 14J-AI smoke complete"
else
  echo "FAIL: Phase 14J-AI smoke failed"
fi

exit "$fail"
