#!/usr/bin/env bash
set -euo pipefail

echo "=== Phase 14J-BJ smoke: rollback safety docs and corrected bootstrap column contract ==="

cd "$(dirname "$0")/../.."

DOC="docs/phase-14j-bj-rollback-safety-docs-and-smoke-artifact.md"
DB="edge_queue.sqlite3"

fail=0

echo
echo "=== required files ==="
for p in "$DOC" "$DB" edge_controller.py ops/db/apply-default-off-worker-registry-lane-metadata.sh; do
  if [ -e "$p" ]; then
    echo "PASS: exists $p"
  else
    echo "FAIL: missing $p"
    fail=1
  fi
done

echo
echo "=== python compile ==="
if python3 -m py_compile edge_controller.py; then
  echo "PASS: edge_controller.py compiles"
else
  echo "FAIL: edge_controller.py compile failed"
  fail=1
fi

echo
echo "=== documentation markers ==="
python3 - <<'PY'
from pathlib import Path

doc = Path("docs/phase-14j-bj-rollback-safety-docs-and-smoke-artifact.md").read_text()

required = [
    "Phase 14J-BI completed as a read-only bootstrap/system check.",
    "`worker_role`",
    "`worker_lane`",
    "`accepts_lane_jobs`",
    "`capabilities`",
    "`disabled`",
    "`current_running_jobs`",
    "`state`",
    "`computed_health`",
    "`disabled_reason` is not part of the canonical Phase 14J worker registry lane metadata schema.",
    "Lane worker activation remains blocked.",
    "persistent lane workers are not active",
    "scheduler lane dispatch is not active",
    "primary/default worker path remains unfiltered",
    "no CT101, Ollama, or live model endpoint call was performed",
    "no production job was mutated",
    "This phase does not:",
]

missing = [s for s in required if s not in doc]
if missing:
    raise SystemExit("FAIL: missing documentation markers: " + repr(missing))
print("PASS: documentation markers present")
PY

echo
echo "=== corrected canonical DB column contract ==="
python3 - <<'PY'
import sqlite3

required = {
    "worker_role",
    "worker_lane",
    "accepts_lane_jobs",
    "capabilities",
    "disabled",
    "current_running_jobs",
    "state",
    "computed_health",
}

con = sqlite3.connect("file:edge_queue.sqlite3?mode=ro", uri=True)
try:
    cols = {row[1] for row in con.execute("PRAGMA table_info(workers)").fetchall()}
finally:
    con.close()

missing = sorted(required - cols)
print("canonical_columns=" + ",".join(sorted(required)))
print("missing_columns=" + (",".join(missing) if missing else "<none>"))

if missing:
    raise SystemExit("FAIL: missing canonical worker lane metadata columns")

print("PASS: canonical worker lane metadata columns present")
PY

echo
echo "=== default-off DB state ==="
python3 - <<'PY'
import sqlite3

con = sqlite3.connect("file:edge_queue.sqlite3?mode=ro", uri=True)
try:
    worker_count = con.execute("SELECT COUNT(*) FROM workers").fetchone()[0]
    lane_enabled = con.execute("SELECT COUNT(*) FROM workers WHERE COALESCE(CAST(accepts_lane_jobs AS INTEGER), 0) != 0").fetchone()[0]
    non_default_lane = con.execute("SELECT COUNT(*) FROM workers WHERE COALESCE(worker_lane, '') != ''").fetchone()[0]
    non_primary_role = con.execute("SELECT COUNT(*) FROM workers WHERE COALESCE(worker_role, 'primary') != 'primary'").fetchone()[0]
finally:
    con.close()

print(f"worker_count={worker_count}")
print(f"lane_enabled_worker_count={lane_enabled}")
print(f"non_default_worker_lane_count={non_default_lane}")
print(f"non_primary_worker_role_count={non_primary_role}")

if lane_enabled != 0:
    raise SystemExit("FAIL: lane-enabled workers present")
if non_default_lane != 0:
    raise SystemExit("FAIL: non-default worker lanes present")
if non_primary_role != 0:
    raise SystemExit("FAIL: non-primary worker roles present")

print("PASS: worker registry remains default-off")
PY

echo
echo "=== env guard ==="
if [ "${EDGE_PERSISTENT_LANE_WORKERS_ENABLED:-}" = "1" ]; then
  echo "FAIL: shell EDGE_PERSISTENT_LANE_WORKERS_ENABLED is enabled"
  fail=1
else
  echo "PASS: shell EDGE_PERSISTENT_LANE_WORKERS_ENABLED absent/disabled"
fi

echo
echo "=== hard-boundary static confirmation ==="
python3 - <<'PY2'
from pathlib import Path

smoke = Path("ops/smoke/check-phase-14j-bj-rollback-safety-docs-and-smoke-artifact.sh").read_text()

blocked_runtime_commands = [
    "systemctl " + "restart",
    "systemctl " + "reload",
    "pct " + "exec",
    "ssh " + "root@",
    "curl " + "http://100.88.245.33:8088",
    "curl " + "http://127.0.0.1:11434",
    "ollama " + "run",
    "ollama " + "pull",
    "apply-default-off-worker-registry-lane-metadata.sh " + "APPLY_DEFAULT_OFF_WORKER_LANE_METADATA",
]

bad = [s for s in blocked_runtime_commands if s in smoke]
if bad:
    raise SystemExit("FAIL: smoke contains blocked runtime command text: " + repr(bad))

print("PASS: smoke contains no blocked runtime command text")
PY2

if [ "$fail" != "0" ]; then
  echo "FAIL: Phase 14J-BJ smoke failed"
  exit 1
fi

echo
echo "PASS: Phase 14J-BJ smoke passed"
