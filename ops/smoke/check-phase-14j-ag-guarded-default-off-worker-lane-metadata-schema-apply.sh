#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

DB="edge_queue.sqlite3"
TARGET_COLUMNS="worker_role worker_lane accepts_lane_jobs capabilities disabled current_running_jobs state computed_health"

echo "=== Phase 14J-AG smoke: worker registry lane metadata schema applied default-off ==="

test -f "$DB"
sqlite3 "$DB" "PRAGMA quick_check;" | grep -Fx "ok" >/dev/null
sqlite3 "$DB" "SELECT name FROM sqlite_master WHERE type='table' AND name='workers';" | grep -Fx "workers" >/dev/null

python3 - "$DB" $TARGET_COLUMNS <<'PY'
import sqlite3
import sys

db = sys.argv[1]
target = sys.argv[2:]
con = sqlite3.connect(f"file:{db}?mode=ro", uri=True)
cols = {row[1] for row in con.execute("PRAGMA table_info(workers)")}
missing = [c for c in target if c not in cols]
if missing:
    raise SystemExit("FAIL: missing target columns: " + ",".join(missing))

enabled_count = con.execute("""
    SELECT COUNT(*)
    FROM workers
    WHERE COALESCE(CAST(accepts_lane_jobs AS INTEGER), 0) <> 0
""").fetchone()[0]

if enabled_count != 0:
    raise SystemExit("FAIL: one or more workers accepts lane jobs after default-off apply")

print("PASS: target columns exist and lane workers remain default-off")
PY

flag="$(
  systemctl show edge-queue-controller -p Environment --value 2>/dev/null \
    | tr ' ' '\n' \
    | grep -E '^EDGE_PERSISTENT_LANE_WORKERS_ENABLED=' \
    | head -n 1 \
    | cut -d= -f2- || true
)"

case "${flag,,}" in
  ""|"0"|"false"|"no"|"off"|"disabled") ;;
  *) echo "FAIL: EDGE_PERSISTENT_LANE_WORKERS_ENABLED is enabled-like"; exit 1 ;;
esac

echo "PASS: EDGE_PERSISTENT_LANE_WORKERS_ENABLED remains absent/disabled"
echo "PASS: Phase 14J-AG smoke complete"
