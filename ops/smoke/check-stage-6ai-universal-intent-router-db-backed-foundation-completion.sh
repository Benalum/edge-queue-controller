#!/usr/bin/env bash
set -euo pipefail

echo "=== Stage 6AI smoke: DB-backed router foundation completion checkpoint ==="

PYTHON_BIN="${PYTHON_BIN:-.venv/bin/python}"
if [ ! -x "$PYTHON_BIN" ]; then
  PYTHON_BIN="python3"
fi
echo "Using Python: $PYTHON_BIN"

DOC="docs/stage-6ai-universal-intent-router-db-backed-foundation-completion.md"

test -f "$DOC"
test -f edge_router_schema.py
test -f edge_router_seed.py
test -f edge_router_lookup.py
test -f edge_intent_router.py
test -f edge_queue.sqlite3

grep -q "Stage 6AI Universal Intent Router DB-Backed Foundation Completion" "$DOC"
grep -q "Stage 6AA" "$DOC"
grep -q "Stage 6AB" "$DOC"
grep -q "Stage 6AC" "$DOC"
grep -q "Stage 6AD" "$DOC"
grep -q "Stage 6AE" "$DOC"
grep -q "Stage 6AF" "$DOC"
grep -q "Stage 6AG" "$DOC"
grep -q "Stage 6AH" "$DOC"
grep -q "does not dispatch actions" "$DOC"
grep -q "does not call models" "$DOC"
grep -q "live router endpoint remains disabled" "$DOC"
grep -q "Stage 6AJ" "$DOC"

echo
echo "=== verify expected stage files exist ==="
for f in \
  docs/stage-6aa-universal-intent-router-sqlite-schema-module.md \
  docs/stage-6ab-universal-intent-router-controller-sqlite-wiring.md \
  docs/stage-6ac-universal-intent-router-seed-data-module.md \
  docs/stage-6ad-universal-intent-router-live-seed-apply.md \
  docs/stage-6ae-universal-intent-router-sqlite-lookup-helpers.md \
  docs/stage-6af-universal-intent-router-db-backed-dry-run-lookup.md \
  docs/stage-6ag-universal-intent-router-db-backed-fixtures.md \
  docs/stage-6ah-universal-intent-router-temporary-enabled-http-smoke.md \
  docs/generated/stage-6ag-db-backed-router-fixtures.json \
  ops/smoke/check-stage-6aa-universal-intent-router-sqlite-schema-module.sh \
  ops/smoke/check-stage-6ab-universal-intent-router-controller-sqlite-wiring.sh \
  ops/smoke/check-stage-6ac-universal-intent-router-seed-data-module.sh \
  ops/smoke/check-stage-6ad-universal-intent-router-live-seed-apply.sh \
  ops/smoke/check-stage-6ae-universal-intent-router-sqlite-lookup-helpers.sh \
  ops/smoke/check-stage-6af-universal-intent-router-db-backed-dry-run-lookup.sh \
  ops/smoke/check-stage-6ag-universal-intent-router-db-backed-fixtures.sh \
  ops/smoke/check-stage-6ah-universal-intent-router-temporary-enabled-http-smoke.sh
do
  test -f "$f"
done

echo
echo "=== compile router modules ==="
"$PYTHON_BIN" -m py_compile \
  edge_router_schema.py \
  edge_router_seed.py \
  edge_router_lookup.py \
  edge_intent_router.py \
  edge_controller.py

echo
echo "=== verify live SQLite router foundation state ==="
"$PYTHON_BIN" - <<'PY'
import sqlite3
from pathlib import Path

from edge_router_lookup import lookup_router_exact_phrase
from edge_router_schema import router_foundation_table_names
from edge_router_seed import router_seed_counts

conn = sqlite3.connect(Path("edge_queue.sqlite3"))
try:
    tables = {
        row[0]
        for row in conn.execute("SELECT name FROM sqlite_master WHERE type='table'")
    }

    missing = sorted(set(router_foundation_table_names()) - tables)
    if missing:
        raise SystemExit(f"missing router tables: {missing}")

    counts = router_seed_counts(conn)
    print("seed counts:", counts)

    assert counts["intent_definitions"] >= 14, counts
    assert counts["intent_routes"] >= 14, counts
    assert counts["global_phrase_bank"] >= 34, counts

    cases = [
        ("next", "en", "study", "study.card.next"),
        ("skip", "en", "study", "study.card.skip"),
        ("show answer", "en", "study", "study.card.answer"),
        ("siguiente", "es", "study", "study.card.next"),
    ]

    for text, language, context, expected in cases:
        result = lookup_router_exact_phrase(
            conn,
            text,
            language_code=language,
            context_domain=context,
        )
        print(text, "=>", result["intent_key"])
        assert result["matched"] is True, result
        assert result["intent_key"] == expected, result
        assert result["dispatch_performed"] is False, result
        assert result["model_call_required"] is False, result

    print("OK: live router foundation state verified")
finally:
    conn.close()
PY

echo
echo "=== verify direct dry-run router response still safe ==="
"$PYTHON_BIN" - <<'PY'
import edge_intent_router

result = edge_intent_router._stage6f_router_response(
    {
        "input": {
            "text": "next",
            "source": "study",
            "surface": "study_session",
        },
        "context": {
            "active_page": "study",
            "profile_language": "en",
            "role": "user",
        },
        "router_options": {
            "dry_run": True,
            "allow_dispatch": False,
            "allow_model_call": False,
        },
    }
)

lookup = result["router_lookup"]["sqlite_phrase_lookup"]

assert result["ok"] is True, result
assert result["dry_run"] is True, result
assert result["dispatch_performed"] is False, result
assert result["model_routing"]["model_call_required"] is False, result
assert result["safety"]["allowed_to_dispatch"] is False, result
assert result["confirmation_policy"]["eligible_for_dispatch"] is False, result
assert result["intent"]["name"] == "study.next", result
assert lookup["matched"] is True, lookup
assert lookup["intent_key"] == "study.card.next", lookup
assert lookup["dispatch_performed"] is False, lookup
assert lookup["model_call_required"] is False, lookup

print("OK: direct dry-run router response remains safe")
PY

echo
echo "=== verify live endpoint remains disabled ==="
router_code="$(curl -sS --max-time 10 -o /tmp/stage6ai-router-disabled.out \
  -w "%{http_code}" \
  -X POST http://127.0.0.1:7070/api/router/dry-run \
  -H 'Content-Type: application/json' \
  --data '{"input":{"text":"next","source":"study","surface":"study_session"},"context":{"active_page":"study"}}' || true)"
echo "router_dry_run_code=$router_code"
cat /tmp/stage6ai-router-disabled.out || true
echo

if [ "$router_code" != "404" ]; then
  echo "FAIL: live router endpoint should remain disabled by default"
  exit 1
fi

echo
echo "PASS: Stage 6AI DB-backed router foundation completion checkpoint passed"
