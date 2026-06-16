#!/usr/bin/env bash
set -euo pipefail

# Phase 14J-AC guarded apply-wrapper artifact.
#
# IMPORTANT:
# This wrapper is created as an artifact in Phase 14J-AC.
# It must not be executed during Phase 14J-AC.
#
# Purpose:
# - Add default-off worker registry lane metadata columns to the SQLite workers table.
# - Apply only missing additive columns.
# - Preserve existing workers as primary/non-lane by default.
# - Never enable EDGE_PERSISTENT_LANE_WORKERS_ENABLED.
#
# Required explicit confirmation:
#   APPLY_DEFAULT_OFF_WORKER_LANE_METADATA

CONFIRM="${1:-}"
REQUIRED_CONFIRM="APPLY_DEFAULT_OFF_WORKER_LANE_METADATA"

if [ "$CONFIRM" != "$REQUIRED_CONFIRM" ]; then
  echo "REFUSE: missing exact confirmation phrase: $REQUIRED_CONFIRM" >&2
  exit 2
fi

DB_PATH="${EDGE_QUEUE_DB_PATH:-${EDGE_CONTROLLER_DB_PATH:-edge_queue.sqlite3}}"
SQL_ARTIFACT="${SQL_ARTIFACT:-ops/db/default-off-worker-registry-lane-metadata.sql}"

if [ "${EDGE_PERSISTENT_LANE_WORKERS_ENABLED:-}" = "1" ]; then
  echo "REFUSE: EDGE_PERSISTENT_LANE_WORKERS_ENABLED is enabled; disable it before schema apply" >&2
  exit 3
fi

if [ ! -f "$DB_PATH" ]; then
  echo "REFUSE: SQLite DB not found: $DB_PATH" >&2
  exit 4
fi

if [ ! -f "$SQL_ARTIFACT" ]; then
  echo "REFUSE: SQL artifact not found: $SQL_ARTIFACT" >&2
  exit 5
fi

BACKUP_PATH="${DB_PATH}.phase14j-lane-metadata.$(date -u +%Y%m%dT%H%M%SZ).bak"
cp -- "$DB_PATH" "$BACKUP_PATH"

python3 - "$DB_PATH" "$SQL_ARTIFACT" "$BACKUP_PATH" <<'PY'
from __future__ import annotations

import re
import sqlite3
import sys
from pathlib import Path

db_path = Path(sys.argv[1])
sql_path = Path(sys.argv[2])
backup_path = Path(sys.argv[3])

required_existing_columns = {
    "worker_id",
    "name",
    "target_name",
    "max_concurrent_jobs",
}

target_columns = [
    ("worker_role", "TEXT DEFAULT 'primary'"),
    ("worker_lane", "TEXT DEFAULT ''"),
    ("accepts_lane_jobs", "INTEGER DEFAULT 0"),
    ("capabilities", "TEXT DEFAULT '[]'"),
    ("disabled", "INTEGER DEFAULT 0"),
    ("current_running_jobs", "INTEGER DEFAULT 0"),
    ("state", "TEXT DEFAULT 'available'"),
    ("computed_health", "TEXT DEFAULT ''"),
]

sql_text = sql_path.read_text()

forbidden_patterns = [
    r"\bDROP\b",
    r"\bDELETE\b",
    r"\bUPDATE\b",
    r"\bINSERT\b",
    r"\bREPLACE\b",
    r"\bCREATE\s+TABLE\b",
    r"\bPRAGMA\s+writable_schema\b",
    r"\bVACUUM\b",
]
bad = [p for p in forbidden_patterns if re.search(p, sql_text, re.IGNORECASE)]
if bad:
    raise SystemExit("REFUSE: SQL artifact contains forbidden destructive markers: " + ", ".join(bad))

conn = sqlite3.connect(db_path)
try:
    conn.row_factory = sqlite3.Row
    tables = {
        row["name"]
        for row in conn.execute("SELECT name FROM sqlite_master WHERE type='table'")
    }
    if "workers" not in tables:
        raise SystemExit("REFUSE: workers table missing")

    columns = {
        row["name"]: row
        for row in conn.execute('PRAGMA table_info("workers")')
    }

    missing_existing = sorted(required_existing_columns - set(columns))
    if missing_existing:
        raise SystemExit("REFUSE: required pre-existing columns missing: " + ",".join(missing_existing))

    applied = []
    skipped = []

    for name, definition in target_columns:
        if name in columns:
            skipped.append(name)
            continue
        sql = f'ALTER TABLE "workers" ADD COLUMN {name} {definition}'
        conn.execute(sql)
        applied.append(name)

    conn.commit()

    final_columns = {
        row["name"]: row
        for row in conn.execute('PRAGMA table_info("workers")')
    }
    missing_final = [name for name, _ in target_columns if name not in final_columns]
    if missing_final:
        raise SystemExit("FAIL: target columns missing after apply: " + ",".join(missing_final))

    print("PASS: default-off worker registry lane metadata schema apply complete")
    print("backup_path=" + str(backup_path))
    print("applied_columns=" + (",".join(applied) if applied else "<none>"))
    print("skipped_existing_columns=" + (",".join(skipped) if skipped else "<none>"))
finally:
    conn.close()
PY
