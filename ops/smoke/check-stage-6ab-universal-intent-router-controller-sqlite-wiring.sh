#!/usr/bin/env bash
set -euo pipefail

echo "=== Stage 6AB smoke: router SQLite schema wired into controller init ==="

PYTHON_BIN="${PYTHON_BIN:-.venv/bin/python}"
if [ ! -x "$PYTHON_BIN" ]; then
  PYTHON_BIN="python3"
fi
echo "Using Python: $PYTHON_BIN"


DOC="docs/stage-6ab-universal-intent-router-controller-sqlite-wiring.md"

test -f "$DOC"
test -f edge_router_schema.py
test -f edge_controller.py

grep -q "Stage 6AB Universal Intent Router Controller SQLite Wiring" "$DOC"
grep -q "does not enable router dispatch" "$DOC"
grep -q "does not enable model calls" "$DOC"
grep -q "intent_definitions" "$DOC"
grep -q "router_feedback" "$DOC"

grep -q "from edge_router_schema import init_router_foundation_schema" edge_controller.py
grep -q "init_router_foundation_schema(conn)" edge_controller.py

echo
echo "=== compile changed modules ==="
"$PYTHON_BIN" -m py_compile edge_router_schema.py edge_controller.py

echo
echo "=== verify temp DB initialization through edge_controller.init_db ==="
"$PYTHON_BIN" - <<'PY'
import sqlite3
import tempfile
from pathlib import Path

import edge_controller
from edge_router_schema import router_foundation_table_names

with tempfile.TemporaryDirectory() as tmp:
    tmp_db = Path(tmp) / "stage6ab-controller-init.sqlite3"

    original_db_path = edge_controller.DB_PATH
    edge_controller.DB_PATH = tmp_db

    try:
        edge_controller.init_db()
    finally:
        edge_controller.DB_PATH = original_db_path

    conn = sqlite3.connect(tmp_db)
    actual = {
        row[0]
        for row in conn.execute(
            "SELECT name FROM sqlite_master WHERE type='table'"
        ).fetchall()
    }

    expected = set(router_foundation_table_names())
    missing = sorted(expected - actual)
    if missing:
        raise SystemExit(f"missing router tables after controller init: {missing}")

    print("OK: edge_controller.init_db created router foundation tables")
    print("router tables:", sorted(expected))

    conn.close()
PY

echo
echo "=== verify router dry-run remains disabled-by-default in code ==="
grep -q "EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED" edge_intent_router.py
grep -q "dry_run_endpoint_never_dispatches" edge_intent_router.py
grep -q '"dispatch_performed": False' edge_intent_router.py
grep -q '"model_call_required": False' edge_intent_router.py

echo
echo "PASS: Stage 6AB router SQLite schema wiring smoke passed"
