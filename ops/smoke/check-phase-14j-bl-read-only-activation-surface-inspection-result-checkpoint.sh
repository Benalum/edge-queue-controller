#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-bl-read-only-activation-surface-inspection-result-checkpoint"
DOC="docs/${PHASE}.md"
SERVICE="edge-queue-controller"
fail=0

echo "=== Phase 14J-BL smoke: read-only activation-surface result checkpoint ==="

require_file() {
  local path="$1"
  if [ -e "$path" ]; then
    echo "PASS: exists $path"
  else
    echo "FAIL: missing $path"
    fail=1
  fi
}

require_doc_marker() {
  local marker="$1"
  if grep -Fq "$marker" "$DOC"; then
    echo "PASS: doc marker found: $marker"
  else
    echo "FAIL: doc marker missing: $marker"
    fail=1
  fi
}

require_source_marker() {
  local marker="$1"
  if grep -Fq "$marker" edge_controller.py; then
    echo "PASS: source marker found: $marker"
  else
    echo "FAIL: source marker missing: $marker"
    fail=1
  fi
}

require_file "$DOC"
require_file "$0"

echo
echo "=== doc markers ==="
require_doc_marker "PHASE_14J_BL_RESULT_CHECKPOINT"
require_doc_marker "RUNTIME_ACTIVATION=not_performed"
require_doc_marker "SERVICE_RESTART_RELOAD=not_performed"
require_doc_marker "CT101_MODEL_JOB_MUTATION=not_performed"
require_doc_marker "LANE_WORKER_ENABLEMENT=not_performed"
require_doc_marker "SCHEDULER_LANE_DISPATCH_ACTIVATION=not_performed"
require_doc_marker "PRIMARY_WORKER_FILTERING_ACTIVATION=not_performed"
require_doc_marker "ROUTER_MODEL_SELECTION_ACTIVATION=not_performed"
require_doc_marker "_phase14j_default_off_worker_registration_metadata"
require_doc_marker "_phase14j_worker_eligible_for_job"
require_doc_marker "_phase14j_filter_workers_for_lane"
require_doc_marker "Activation remains blocked"

echo
echo "=== source helper markers ==="
require_source_marker "def _phase14j_lane_workers_enabled"
require_source_marker "def _phase14j_default_off_worker_registration_metadata"
require_source_marker "def _phase14j_job_lane_metadata"
require_source_marker "def _phase14j_worker_lane_metadata"
require_source_marker "def _phase14j_worker_eligible_for_job"
require_source_marker "def _phase14j_filter_workers_for_lane"
require_source_marker "phase14j_lane_scheduler_gate_enabled = _phase14j_lane_workers_enabled()"
require_source_marker "workers = _phase14j_filter_workers_for_lane(workers, job)"

echo
echo "=== python compile ==="
if python3 -m py_compile edge_controller.py; then
  echo "PASS: edge_controller.py compiles"
else
  echo "FAIL: edge_controller.py compile failed"
  fail=1
fi

echo
echo "=== helper behavior static verification ==="
python3 - <<'PY' || fail=1
from pathlib import Path

text = Path("edge_controller.py").read_text()
required = [
    "def _phase14j_lane_workers_enabled():",
    "EDGE_PERSISTENT_LANE_WORKERS_ENABLED",
    "def _phase14j_filter_workers_for_lane(workers, job):",
    "if not _phase14j_lane_workers_enabled():",
    "return list(workers)",
    "def _phase14j_worker_eligible_for_job(worker, job):",
    '"reason_code": "lane_gate_disabled"',
    "registration_metadata = _phase14j_default_off_worker_registration_metadata()",
]
missing = [marker for marker in required if marker not in text]
if missing:
    raise SystemExit("FAIL: missing helper behavior markers: " + ", ".join(missing))
print("PASS: Phase 14J helper behavior markers verified")
PY

echo
echo "=== SQLite read-only default-off verification ==="
python3 - <<'PY' || fail=1
from pathlib import Path
import sqlite3

db = Path("edge_queue.sqlite3")
con = sqlite3.connect(f"file:{db.resolve()}?mode=ro", uri=True)
con.row_factory = sqlite3.Row

quick = con.execute("PRAGMA quick_check").fetchone()[0]
print(f"quick_check={quick}")
if quick != "ok":
    raise SystemExit("FAIL: SQLite quick_check failed")

cols = [r[1] for r in con.execute("PRAGMA table_info(workers)").fetchall()]
expected = [
    "worker_role",
    "worker_lane",
    "accepts_lane_jobs",
    "capabilities",
    "disabled",
    "current_running_jobs",
    "state",
    "computed_health",
]
missing = [c for c in expected if c not in cols]
if missing:
    raise SystemExit("FAIL: missing canonical worker metadata columns: " + ",".join(missing))

print("PASS: canonical 8 worker lane metadata columns present")
print(f"disabled_reason_present={'yes' if 'disabled_reason' in cols else 'no'}; not canonical/required")

row = con.execute("""
SELECT
  COUNT(*) AS worker_count,
  COALESCE(SUM(CASE WHEN accepts_lane_jobs IN (1, '1', 'true', 'TRUE', 'yes', 'YES', 'on', 'ON') THEN 1 ELSE 0 END), 0) AS lane_enabled_worker_count,
  COALESCE(SUM(CASE WHEN worker_lane IS NOT NULL AND worker_lane NOT IN ('', 'default') THEN 1 ELSE 0 END), 0) AS non_default_worker_lane_count,
  COALESCE(SUM(CASE WHEN worker_role IS NOT NULL AND worker_role NOT IN ('', 'primary') THEN 1 ELSE 0 END), 0) AS non_primary_worker_role_count
FROM workers
""").fetchone()

for key in row.keys():
    print(f"{key}={row[key]}")
    if int(row[key]) != 0:
        raise SystemExit(f"FAIL: expected {key}=0")

print("PASS: DB worker metadata remains default-off")
con.close()
PY

echo
echo "=== persistent lane worker flag guard ==="
shell_flag="${EDGE_PERSISTENT_LANE_WORKERS_ENABLED-<unset>}"
echo "shell_EDGE_PERSISTENT_LANE_WORKERS_ENABLED=${shell_flag}"
case "$shell_flag" in
  1|true|TRUE|yes|YES|on|ON)
    echo "FAIL: shell persistent lane worker flag enabled"
    fail=1
    ;;
  *)
    echo "PASS: shell persistent lane worker flag absent/disabled"
    ;;
esac

service_flag="$(
  systemctl show "$SERVICE" -p Environment --value 2>/dev/null \
    | tr ' ' '\n' \
    | grep '^EDGE_PERSISTENT_LANE_WORKERS_ENABLED=' || true
)"

if [ -z "$service_flag" ]; then
  echo "PASS: service persistent lane worker flag absent"
else
  service_value="${service_flag#EDGE_PERSISTENT_LANE_WORKERS_ENABLED=}"
  case "$service_value" in
    1|true|TRUE|yes|YES|on|ON)
      echo "FAIL: service persistent lane worker flag enabled"
      fail=1
      ;;
    *)
      echo "PASS: service persistent lane worker flag present but disabled"
      ;;
  esac
fi

echo
echo "=== no runtime activation confirmation ==="
echo "RUNTIME_ACTIVATION=not_performed"
echo "SERVICE_RESTART_RELOAD=not_performed"
echo "CT101_MODEL_JOB_MUTATION=not_performed"
echo "JOB_MUTATION=not_performed"
echo "LANE_WORKER_ENABLEMENT=not_performed"
echo "SCHEDULER_LANE_DISPATCH_ACTIVATION=not_performed"
echo "PRIMARY_WORKER_FILTERING_ACTIVATION=not_performed"
echo "ROUTER_MODEL_SELECTION_ACTIVATION=not_performed"

echo
if [ "$fail" = "0" ]; then
  echo "PASS: Phase 14J-BL result checkpoint smoke passed"
else
  echo "FAIL: Phase 14J-BL result checkpoint smoke failed"
fi

exit "$fail"
