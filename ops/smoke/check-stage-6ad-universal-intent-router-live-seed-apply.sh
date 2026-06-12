#!/usr/bin/env bash
set -euo pipefail

echo "=== Stage 6AD smoke: Universal Intent Router live seed apply ==="

PYTHON_BIN="${PYTHON_BIN:-.venv/bin/python}"
if [ ! -x "$PYTHON_BIN" ]; then
  PYTHON_BIN="python3"
fi
echo "Using Python: $PYTHON_BIN"

DOC="docs/stage-6ad-universal-intent-router-live-seed-apply.md"

test -f "$DOC"
test -f edge_router_schema.py
test -f edge_router_seed.py
test -f edge_queue.sqlite3

grep -q "Stage 6AD Universal Intent Router Live Seed Apply" "$DOC"
grep -q "did not wire router dispatch" "$DOC"
grep -q "did not enable model calls" "$DOC"
grep -q "did not restart the controller" "$DOC"
grep -q "Stage 6AE Universal Intent Router SQLite Lookup Helpers" "$DOC"

echo
echo "=== compile router modules ==="
"$PYTHON_BIN" -m py_compile edge_router_schema.py edge_router_seed.py edge_controller.py

echo
echo "=== verify live SQLite router seed counts ==="
"$PYTHON_BIN" - <<'PY'
import sqlite3
from pathlib import Path

from edge_router_schema import router_foundation_table_names
from edge_router_seed import router_seed_counts

db = Path("edge_queue.sqlite3")
if not db.exists():
    raise SystemExit("edge_queue.sqlite3 not found")

conn = sqlite3.connect(db)
try:
    actual_tables = {
        row[0]
        for row in conn.execute("SELECT name FROM sqlite_master WHERE type='table'")
    }

    expected_tables = set(router_foundation_table_names())
    missing = sorted(expected_tables - actual_tables)
    if missing:
        raise SystemExit(f"missing router tables: {missing}")

    counts = router_seed_counts(conn)
    print("seed counts:", counts)

    if counts["intent_definitions"] < 14:
        raise SystemExit("intent_definitions seed count too low")
    if counts["intent_routes"] < 14:
        raise SystemExit("intent_routes seed count too low")
    if counts["global_phrase_bank"] < 34:
        raise SystemExit("global_phrase_bank seed count too low")

    required_phrases = [
        ("en", "next", "study.card.next"),
        ("en", "skip", "study.card.skip"),
        ("en", "show answer", "study.card.answer"),
        ("en", "correct", "study.card.correct"),
        ("en", "wrong", "study.card.incorrect"),
        ("es", "siguiente", "study.card.next"),
        ("es", "omitir", "study.card.skip"),
        ("es", "mostrar respuesta", "study.card.answer"),
    ]

    for language_code, normalized_phrase, intent_key in required_phrases:
        count = conn.execute(
            """
            SELECT COUNT(*)
            FROM global_phrase_bank
            WHERE language_code = ?
              AND normalized_phrase = ?
              AND intent_key = ?
              AND enabled = 1
            """,
            (language_code, normalized_phrase, intent_key),
        ).fetchone()[0]
        if count < 1:
            raise SystemExit(
                f"missing phrase mapping: {language_code} {normalized_phrase} -> {intent_key}"
            )

    print("OK: live router seed data is present")
finally:
    conn.close()
PY

echo
echo "=== verify controller is active ==="
systemctl is-active edge-queue-controller | grep -q '^active$'

echo
echo "=== verify controller health endpoint returns HTTP 200 ==="
code="$(curl -sS --max-time 10 -o /tmp/stage6ad-health.out -w "%{http_code}" http://127.0.0.1:7070/health || true)"
echo "health_code=$code"
cat /tmp/stage6ad-health.out || true
echo
if [ "$code" != "200" ]; then
  echo "FAIL: controller health should return HTTP 200"
  exit 1
fi

echo
echo "=== verify router dry-run endpoint remains disabled ==="
router_code="$(curl -sS --max-time 10 -o /tmp/stage6ad-router-disabled.out \
  -w "%{http_code}" \
  -X POST http://127.0.0.1:7070/api/router/dry-run \
  -H 'Content-Type: application/json' \
  --data '{"input":"next","page_context":"study"}' || true)"
echo "router_dry_run_code=$router_code"
cat /tmp/stage6ad-router-disabled.out || true
echo
if [ "$router_code" != "404" ]; then
  echo "FAIL: router dry-run endpoint should remain disabled by default"
  exit 1
fi

echo
echo "PASS: Stage 6AD live router seed apply smoke passed"
