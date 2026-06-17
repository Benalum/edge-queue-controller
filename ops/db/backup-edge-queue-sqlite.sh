#!/usr/bin/env bash
set -euo pipefail

export PAGER=cat

# Phase 14J-FV marker: sqlite3 backup API

DB_PATH="${EDGE_QUEUE_SQLITE_DB_PATH:-${EDGE_QUEUE_DB_PATH:-${EDGE_CONTROLLER_DB_PATH:-edge_queue.sqlite3}}}"
BACKUP_ROOT="${EDGE_QUEUE_SQLITE_BACKUP_DIR:-$HOME/Desktop/ai-platform-controller-backups/sqlite}"
RETENTION_DAYS="${EDGE_QUEUE_SQLITE_BACKUP_RETENTION_DAYS:-14}"

if [ ! -f "$DB_PATH" ]; then
  echo "FAIL: SQLite DB not found: $DB_PATH" >&2
  exit 1
fi

mkdir -p "$BACKUP_ROOT"
chmod 700 "$BACKUP_ROOT"

TS="$(date +%Y%m%d-%H%M%S)"
BACKUP_FILE="$BACKUP_ROOT/edge-queue-$TS.sqlite3"
MANIFEST_FILE="$BACKUP_ROOT/edge-queue-$TS.txt"
LATEST_LINK="$BACKUP_ROOT/latest.sqlite3"

echo "=== edge queue SQLite backup ==="
echo "backup_root=$BACKUP_ROOT"
echo "source_db=$DB_PATH"

python3 - "$DB_PATH" "$BACKUP_FILE" "$MANIFEST_FILE" <<'PY'
import sqlite3
import sys
from pathlib import Path

src = Path(sys.argv[1]).resolve()
dst = Path(sys.argv[2]).resolve()
manifest = Path(sys.argv[3]).resolve()

src_conn = sqlite3.connect(f"file:{src}?mode=ro", uri=True)
dst_conn = sqlite3.connect(str(dst))

with dst_conn:
    src_conn.backup(dst_conn)

dst_conn.close()
src_conn.close()

dst.chmod(0o600)

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
    return {
        "quick": quick,
        "tables": tables,
        "counts": counts,
        "indexes": indexes,
        "total_rows": sum(counts.values()),
    }

summary = summarize(dst, "backup")
if summary["quick"] != "ok":
    raise SystemExit(f"FAIL: backup quick_check={summary['quick']}")

with manifest.open("w", encoding="utf-8") as fh:
    fh.write("AI Platform Edge Queue SQLite Backup\n")
    fh.write(f"source_db_name={src.name}\n")
    fh.write(f"backup_file={dst}\n")
    fh.write(f"backup_size_bytes={dst.stat().st_size}\n")
    fh.write(f"quick_check={summary['quick']}\n")
    fh.write(f"table_count={len(summary['tables'])}\n")
    fh.write(f"index_count={len(summary['indexes'])}\n")
    fh.write(f"total_rows_across_tables={summary['total_rows']}\n")
    fh.write("\n")
    fh.write("table_counts_no_row_dump:\n")
    for table in summary["tables"]:
        fh.write(f"{table}|rows={summary['counts'][table]}\n")

manifest.chmod(0o600)

print(f"BACKUP_FILE={dst}")
print(f"MANIFEST_FILE={manifest}")
print(f"BACKUP_SIZE_BYTES={dst.stat().st_size}")
print(f"BACKUP_QUICK_CHECK={summary['quick']}")
print(f"BACKUP_TABLE_COUNT={len(summary['tables'])}")
print(f"BACKUP_INDEX_COUNT={len(summary['indexes'])}")
print(f"BACKUP_TOTAL_ROWS_ACROSS_TABLES={summary['total_rows']}")
PY

if [ ! -s "$BACKUP_FILE" ]; then
  echo "FAIL: backup file missing or empty: $BACKUP_FILE" >&2
  exit 1
fi

if [ ! -s "$MANIFEST_FILE" ]; then
  echo "FAIL: manifest file missing or empty: $MANIFEST_FILE" >&2
  exit 1
fi

chmod 600 "$BACKUP_FILE" "$MANIFEST_FILE"
ln -sfn "$BACKUP_FILE" "$LATEST_LINK"

find "$BACKUP_ROOT" -maxdepth 1 -type f -name 'edge-queue-*.sqlite3' -mtime +"$RETENTION_DAYS" -delete
find "$BACKUP_ROOT" -maxdepth 1 -type f -name 'edge-queue-*.txt' -mtime +"$RETENTION_DAYS" -delete

echo "PASS: edge queue SQLite backup created"
echo "BACKUP_FILE=$BACKUP_FILE"
echo "MANIFEST_FILE=$MANIFEST_FILE"
