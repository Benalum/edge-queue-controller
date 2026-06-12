#!/usr/bin/env bash
set -euo pipefail

echo "=== Stage 6AC smoke: Universal Intent Router seed data module ==="

PYTHON_BIN="${PYTHON_BIN:-.venv/bin/python}"
if [ ! -x "$PYTHON_BIN" ]; then
  PYTHON_BIN="python3"
fi
echo "Using Python: $PYTHON_BIN"

DOC="docs/stage-6ac-universal-intent-router-seed-data-module.md"
MOD="edge_router_seed.py"

test -f "$DOC"
test -f "$MOD"
test -f edge_router_schema.py

grep -q "Stage 6AC Universal Intent Router Seed Data Module" "$DOC"
grep -q "This stage does not change runtime behavior" "$DOC"
grep -q "does not wire router dispatch" "$DOC"
grep -q "does not call models" "$DOC"
grep -q "global phrase bank" "$DOC"

grep -q "def seed_router_foundation_data" "$MOD"
grep -q "def router_seed_counts" "$MOD"
grep -q "study.card.skip" "$MOD"
grep -q "calendar.event.create" "$MOD"
grep -q "siguiente" "$MOD"

echo
echo "=== compile modules ==="
"$PYTHON_BIN" -m py_compile edge_router_schema.py edge_router_seed.py edge_controller.py

echo
echo "=== initialize and seed temporary SQLite database ==="
"$PYTHON_BIN" - <<'PY'
import sqlite3
import tempfile
from pathlib import Path

from edge_router_schema import init_router_foundation_schema
from edge_router_seed import seed_router_foundation_data, router_seed_counts

with tempfile.TemporaryDirectory() as tmp:
    db = Path(tmp) / "stage6ac-seed.sqlite3"
    conn = sqlite3.connect(db)

    # Minimal app_users table satisfies FK references in temporary schema tests.
    conn.execute("""
        CREATE TABLE IF NOT EXISTS app_users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT NOT NULL UNIQUE
        )
    """)

    init_router_foundation_schema(conn)
    seed_router_foundation_data(conn)
    conn.commit()

    counts = router_seed_counts(conn)
    print("seed counts:", counts)

    assert counts["intent_definitions"] >= 14, counts
    assert counts["intent_routes"] >= 14, counts
    assert counts["global_phrase_bank"] >= 30, counts

    checks = [
        ("intent_definitions", "intent_key", "study.card.skip"),
        ("intent_definitions", "intent_key", "companion.chat.message"),
        ("intent_definitions", "intent_key", "calendar.event.create"),
        ("intent_routes", "intent_key", "study.card.answer"),
        ("global_phrase_bank", "normalized_phrase", "siguiente"),
        ("global_phrase_bank", "normalized_phrase", "show answer"),
    ]

    for table, col, value in checks:
        row = conn.execute(
            f"SELECT COUNT(*) FROM {table} WHERE {col} = ?",
            (value,),
        ).fetchone()
        if int(row[0]) < 1:
            raise SystemExit(f"missing seed {table}.{col}={value}")

    # Idempotency check.
    seed_router_foundation_data(conn)
    conn.commit()
    counts2 = router_seed_counts(conn)
    if counts != counts2:
        raise SystemExit(f"seed not idempotent: before={counts} after={counts2}")

    print("OK: temporary SQLite router seed data initialized and idempotent")
    conn.close()
PY

echo
echo "=== verify seed is not wired into controller yet ==="
if grep -q "seed_router_foundation_data" edge_controller.py; then
  echo "FAIL: Stage 6AC should not wire seed data into edge_controller.py yet"
  exit 1
fi

echo
echo "PASS: Stage 6AC Universal Intent Router seed data module smoke passed"
