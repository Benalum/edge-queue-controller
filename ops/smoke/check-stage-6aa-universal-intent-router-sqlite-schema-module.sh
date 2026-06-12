#!/usr/bin/env bash
set -euo pipefail

echo "=== Stage 6AA smoke: Universal Intent Router SQLite schema module ==="

DOC="docs/stage-6aa-universal-intent-router-sqlite-schema-module.md"
MOD="edge_router_schema.py"

test -f "$DOC"
test -f "$MOD"

grep -q "Stage 6AA Universal Intent Router SQLite Schema Module" "$DOC"
grep -q "This stage does not change runtime behavior" "$DOC"
grep -q "does not wire the schema into" "$DOC"
grep -q "intent_definitions" "$DOC"
grep -q "router_logs" "$DOC"
grep -q "router_feedback" "$DOC"

grep -q "def init_router_foundation_schema" "$MOD"
grep -q "def router_foundation_table_names" "$MOD"
grep -q "CREATE TABLE IF NOT EXISTS intent_definitions" "$MOD"
grep -q "CREATE TABLE IF NOT EXISTS user_phrase_bank" "$MOD"
grep -q "CREATE TABLE IF NOT EXISTS router_logs" "$MOD"

echo
echo "=== compile module ==="
python3 -m py_compile "$MOD"

echo
echo "=== initialize temporary SQLite database ==="
python3 - <<'PY'
import sqlite3
import tempfile
from pathlib import Path

import edge_router_schema

with tempfile.TemporaryDirectory() as tmp:
    db_path = Path(tmp) / "router_schema_test.sqlite3"
    conn = sqlite3.connect(db_path)

    edge_router_schema.init_router_foundation_schema(conn)
    conn.commit()

    actual = {
        row[0]
        for row in conn.execute(
            "SELECT name FROM sqlite_master WHERE type='table'"
        ).fetchall()
    }

    expected = set(edge_router_schema.router_foundation_table_names())
    missing = sorted(expected - actual)
    if missing:
        raise SystemExit(f"missing router tables: {missing}")

    indexes = {
        row[0]
        for row in conn.execute(
            "SELECT name FROM sqlite_master WHERE type='index'"
        ).fetchall()
    }

    required_indexes = {
        "idx_intent_definitions_domain",
        "idx_global_phrase_bank_lookup",
        "idx_user_phrase_bank_lookup",
        "idx_router_logs_user_created",
        "idx_router_resolution_steps_log",
        "idx_router_feedback_user_created",
    }

    missing_indexes = sorted(required_indexes - indexes)
    if missing_indexes:
        raise SystemExit(f"missing router indexes: {missing_indexes}")

    print("OK: temporary SQLite router schema initialized")
    print("tables:", sorted(expected))

    conn.close()
PY

echo
echo "=== verify schema not wired into controller yet ==="
if grep -q "init_router_foundation_schema" edge_controller.py; then
  echo "FAIL: Stage 6AA should not wire router schema into edge_controller.py yet"
  exit 1
fi

echo
echo "PASS: Stage 6AA Universal Intent Router SQLite schema module smoke passed"
