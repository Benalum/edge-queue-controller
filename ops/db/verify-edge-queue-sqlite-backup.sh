#!/usr/bin/env bash
set -euo pipefail

export PAGER=cat

if [ "${1:-}" = "" ]; then
  echo "usage: $0 <backup-sqlite-file> [live-db-path]" >&2
  exit 2
fi

BACKUP_FILE="$1"
LIVE_DB="${2:-${EDGE_QUEUE_SQLITE_DB_PATH:-${EDGE_QUEUE_DB_PATH:-${EDGE_CONTROLLER_DB_PATH:-edge_queue.sqlite3}}}}"

if [ ! -f "$BACKUP_FILE" ]; then
  echo "FAIL: backup file not found: $BACKUP_FILE" >&2
  exit 1
fi

if [ ! -f "$LIVE_DB" ]; then
  echo "FAIL: live DB not found for comparison: $LIVE_DB" >&2
  exit 1
fi

TMPDIR_VERIFY="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_VERIFY"' EXIT
RESTORE_COPY="$TMPDIR_VERIFY/restore-copy.sqlite3"

cp -- "$BACKUP_FILE" "$RESTORE_COPY"
chmod 600 "$RESTORE_COPY"

python3 - "$LIVE_DB" "$BACKUP_FILE" "$RESTORE_COPY" <<'PY'
import sqlite3
import sys
from pathlib import Path

live = Path(sys.argv[1]).resolve()
backup = Path(sys.argv[2]).resolve()
restore = Path(sys.argv[3]).resolve()

def summarize(path: Path, label: str):
    conn = sqlite3.connect(f"file:{path}?mode=ro", uri=True)
    conn.row_factory = sqlite3.Row
    quick = conn.execute("PRAGMA quick_check").fetchone()[0]
    tables = [
        row["name"]
        for row in conn.execute(
            "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name"
        )
    ]
    counts = {}
    for table in tables:
        safe = table.replace('"', '""')
        counts[table] = conn.execute(f'SELECT COUNT(*) FROM "{safe}"').fetchone()[0]
    indexes = [
        row["name"]
        for row in conn.execute(
            "SELECT name FROM sqlite_master WHERE type='index' AND name NOT LIKE 'sqlite_%' ORDER BY name"
        )
    ]
    conn.close()

    print(f"{label}_quick_check={quick}")
    print(f"{label}_table_count={len(tables)}")
    print(f"{label}_index_count={len(indexes)}")
    print(f"{label}_total_rows_across_tables={sum(counts.values())}")
    return tables, counts, indexes

live_tables, live_counts, live_indexes = summarize(live, "live")
backup_tables, backup_counts, backup_indexes = summarize(backup, "backup")
restore_tables, restore_counts, restore_indexes = summarize(restore, "restore")

if backup_tables != restore_tables:
    print("FAIL: backup/restore table list mismatch")
    raise SystemExit(1)

if backup_counts != restore_counts:
    print("FAIL: backup/restore row-count mismatch")
    raise SystemExit(1)

if backup_indexes != restore_indexes:
    print("FAIL: backup/restore index list mismatch")
    raise SystemExit(1)

if live_tables != backup_tables:
    print("FAIL: live/backup table list mismatch")
    raise SystemExit(1)

# Live DB may have changed after backup if the controller is active, so row-count drift is a warning,
# not a failure. The backup/restore copy must remain internally consistent.
if live_counts != backup_counts:
    print("WARN: live/backup row counts differ; live DB may have changed after backup")
    for table in live_tables:
        if live_counts.get(table) != backup_counts.get(table):
            print(f"DRIFT table={table} live={live_counts.get(table)} backup={backup_counts.get(table)}")

if live_indexes != backup_indexes:
    print("FAIL: live/backup index list mismatch")
    raise SystemExit(1)

print("PASS: SQLite backup restore verification passed")
PY
