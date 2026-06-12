#!/usr/bin/env bash
set -euo pipefail

echo "=== Stage 6AE smoke: Universal Intent Router SQLite lookup helpers ==="

PYTHON_BIN="${PYTHON_BIN:-.venv/bin/python}"
if [ ! -x "$PYTHON_BIN" ]; then
  PYTHON_BIN="python3"
fi
echo "Using Python: $PYTHON_BIN"

DOC="docs/stage-6ae-universal-intent-router-sqlite-lookup-helpers.md"
MOD="edge_router_lookup.py"

test -f "$DOC"
test -f "$MOD"
test -f edge_router_schema.py
test -f edge_router_seed.py

grep -q "Stage 6AE Universal Intent Router SQLite Lookup Helpers" "$DOC"
grep -q "does not wire router dispatch" "$DOC"
grep -q "does not call models" "$DOC"
grep -q "dispatch_performed=false" "$DOC"
grep -q "model_call_required=false" "$DOC"

grep -q "def normalize_router_phrase" "$MOD"
grep -q "def lookup_global_phrase" "$MOD"
grep -q "def lookup_router_exact_phrase" "$MOD"
grep -q '"dispatch_performed": False' "$MOD"
grep -q '"model_call_required": False' "$MOD"

echo
echo "=== compile router modules ==="
"$PYTHON_BIN" -m py_compile \
  edge_router_schema.py \
  edge_router_seed.py \
  edge_router_lookup.py \
  edge_controller.py

echo
echo "=== test lookup helper against temporary seeded SQLite ==="
"$PYTHON_BIN" - <<'PY'
import sqlite3
import tempfile
from pathlib import Path

from edge_router_lookup import normalize_router_phrase, lookup_router_exact_phrase
from edge_router_schema import init_router_foundation_schema
from edge_router_seed import seed_router_foundation_data

with tempfile.TemporaryDirectory() as tmp:
    db = Path(tmp) / "stage6ae-lookup.sqlite3"
    conn = sqlite3.connect(db)
    conn.execute("""
        CREATE TABLE IF NOT EXISTS app_users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT NOT NULL UNIQUE
        )
    """)
    init_router_foundation_schema(conn)
    seed_router_foundation_data(conn)
    conn.commit()

    assert normalize_router_phrase("I don't know") == "i dont know"
    assert normalize_router_phrase("Próximo") == "proximo"
    assert normalize_router_phrase("  Show   answer!! ") == "show answer"

    cases = [
        ("next", "en", "study", "study.card.next"),
        ("n", "en", "study", "study.card.next"),
        ("skip", "en", "study", "study.card.skip"),
        ("I don't know", "en", "study", "study.card.skip"),
        ("show answer", "en", "study", "study.card.answer"),
        ("correct", "en", "study", "study.card.correct"),
        ("wrong", "en", "study", "study.card.incorrect"),
        ("siguiente", "es", "study", "study.card.next"),
        ("próximo", "es", "study", "study.card.next"),
        ("omitir", "es", "study", "study.card.skip"),
        ("mostrar respuesta", "es", "study", "study.card.answer"),
    ]

    for phrase, language, context, expected_intent in cases:
        result = lookup_router_exact_phrase(
            conn,
            phrase,
            language_code=language,
            context_domain=context,
        )
        assert result["ok"] is True, result
        assert result["matched"] is True, result
        assert result["intent_key"] == expected_intent, result
        assert result["dispatch_performed"] is False, result
        assert result["model_call_required"] is False, result
        assert result["intent"] is not None, result
        assert result["route"] is not None, result

    miss = lookup_router_exact_phrase(conn, "definitely unknown phrase", language_code="en", context_domain="study")
    assert miss["ok"] is True, miss
    assert miss["matched"] is False, miss
    assert miss["error_code"] == "no_phrase_match", miss
    assert miss["dispatch_performed"] is False, miss
    assert miss["model_call_required"] is False, miss

    empty = lookup_router_exact_phrase(conn, "   ", language_code="en", context_domain="study")
    assert empty["ok"] is False, empty
    assert empty["matched"] is False, empty
    assert empty["error_code"] == "empty_input", empty

    print("OK: temporary seeded SQLite exact lookups passed")
    conn.close()
PY

echo
echo "=== test lookup helper against live SQLite seed data ==="
"$PYTHON_BIN" - <<'PY'
import sqlite3
from pathlib import Path

from edge_router_lookup import lookup_router_exact_phrase

db = Path("edge_queue.sqlite3")
if not db.exists():
    raise SystemExit("edge_queue.sqlite3 not found")

conn = sqlite3.connect(db)
try:
    cases = [
        ("next", "en", "study", "study.card.next"),
        ("skip", "en", "study", "study.card.skip"),
        ("show answer", "en", "study", "study.card.answer"),
        ("siguiente", "es", "study", "study.card.next"),
    ]

    for phrase, language, context, expected_intent in cases:
        result = lookup_router_exact_phrase(
            conn,
            phrase,
            language_code=language,
            context_domain=context,
        )
        print(phrase, "=>", result["intent_key"])
        assert result["matched"] is True, result
        assert result["intent_key"] == expected_intent, result
        assert result["dispatch_performed"] is False, result
        assert result["model_call_required"] is False, result

    print("OK: live SQLite exact lookups passed")
finally:
    conn.close()
PY

echo
echo "=== verify lookup is not wired into controller yet ==="
if grep -q "lookup_router_exact_phrase" edge_controller.py; then
  echo "FAIL: Stage 6AE should not wire lookup into edge_controller.py yet"
  exit 1
fi

echo
echo "PASS: Stage 6AE Universal Intent Router SQLite lookup helpers smoke passed"
