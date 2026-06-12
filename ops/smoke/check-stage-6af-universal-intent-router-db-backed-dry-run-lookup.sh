#!/usr/bin/env bash
set -euo pipefail

echo "=== Stage 6AF smoke: DB-backed dry-run router lookup observability ==="

PYTHON_BIN="${PYTHON_BIN:-.venv/bin/python}"
if [ ! -x "$PYTHON_BIN" ]; then
  PYTHON_BIN="python3"
fi
echo "Using Python: $PYTHON_BIN"

DOC="docs/stage-6af-universal-intent-router-db-backed-dry-run-lookup.md"

test -f "$DOC"
test -f edge_intent_router.py
test -f edge_router_lookup.py
test -f edge_queue.sqlite3

grep -q "Stage 6AF Universal Intent Router DB-Backed Dry-Run Lookup" "$DOC"
grep -q "does not wire router dispatch" "$DOC"
grep -q "does not call models" "$DOC"
grep -q "does not enable the router endpoint by default" "$DOC"
grep -q "Stage 6AF does not replace legacy dry-run intent names yet" "$DOC"

grep -q "def _stage6af_sqlite_phrase_lookup" edge_intent_router.py
grep -q '"router_lookup":' edge_intent_router.py
grep -q '"sqlite_phrase_lookup"' edge_intent_router.py
grep -q '"step": "sqlite_phrase_lookup"' edge_intent_router.py
grep -q '"dispatch_performed": False' edge_intent_router.py
grep -q '"model_call_required": False' edge_intent_router.py

echo
echo "=== compile modules ==="
"$PYTHON_BIN" -m py_compile \
  edge_router_lookup.py \
  edge_router_schema.py \
  edge_router_seed.py \
  edge_intent_router.py \
  edge_controller.py

echo
echo "=== direct helper DB-backed lookup smoke ==="
"$PYTHON_BIN" - <<'PY'
import edge_intent_router

cases = [
    ("next", "study.card.next", "study.next"),
    ("skip", "study.card.skip", "study.skip"),
    ("show answer", "study.card.answer", "study.answer"),
    ("siguiente", "study.card.next", "study.next"),
]

for text, expected_db_intent, expected_legacy_intent in cases:
    result = edge_intent_router._stage6f_router_response(
        {
            "input": {
                "text": text,
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

    print(text, "legacy=", result["intent"]["name"], "db=", lookup.get("intent_key"))

    assert result["ok"] is True, result
    assert result["dry_run"] is True, result
    assert result["dispatch_performed"] is False, result
    assert result["model_routing"]["model_call_required"] is False, result
    assert result["safety"]["allowed_to_dispatch"] is False, result
    assert result["confirmation_policy"]["eligible_for_dispatch"] is False, result

    assert result["intent"]["name"] == expected_legacy_intent, result
    assert lookup["matched"] is True, lookup
    assert lookup["intent_key"] == expected_db_intent, lookup
    assert lookup["dispatch_performed"] is False, lookup
    assert lookup["model_call_required"] is False, lookup

    assert result["decision_trace"][0]["step"] == "normalize_input", result["decision_trace"]
    assert any(step["step"] == "sqlite_phrase_lookup" for step in result["decision_trace"]), result["decision_trace"]
    assert result["decision_trace"][-1]["step"] == "rule_result", result["decision_trace"]

blocked = edge_intent_router._stage6f_router_response(
    {
        "input": {
            "text": "next",
            "source": "admin",
            "surface": "admin",
        },
        "context": {
            "active_page": "admin",
            "role": "admin",
        },
    }
)

blocked_lookup = blocked["router_lookup"]["sqlite_phrase_lookup"]
assert blocked["source_surface_policy"]["allowed"] is False, blocked
assert blocked_lookup["matched"] is False, blocked_lookup
assert blocked_lookup["error_code"] == "source_surface_policy_blocked", blocked_lookup
assert blocked["dispatch_performed"] is False, blocked
assert blocked["model_routing"]["model_call_required"] is False, blocked
assert blocked["safety"]["allowed_to_dispatch"] is False, blocked
assert blocked["decision_trace"][-1]["step"] == "rule_result", blocked["decision_trace"]

print("OK: Stage 6AF direct helper DB lookup smoke passed")
PY

echo
echo "=== Stage 6AF local schema compatibility check ==="
"$PYTHON_BIN" - <<'PY2'
import edge_intent_router

fixtures = [
    {
        "name": "study_next_en",
        "body": {
            "input": {"text": "next", "source": "study", "surface": "study_session"},
            "context": {"active_page": "study"},
        },
    },
    {
        "name": "study_skip_en",
        "body": {
            "input": {"text": "skip", "source": "study", "surface": "study_session"},
            "context": {"active_page": "study"},
        },
    },
    {
        "name": "companion_chat_en",
        "body": {
            "input": {"text": "hello", "source": "companion", "surface": "companion_chat"},
            "context": {"active_page": "companion"},
        },
    },
    {
        "name": "blocked_admin_source",
        "body": {
            "input": {"text": "next", "source": "admin", "surface": "admin"},
            "context": {"active_page": "admin"},
        },
    },
]

for fixture in fixtures:
    result = edge_intent_router._stage6f_router_response(fixture["body"])
    name = fixture["name"]

    assert result["ok"] is True, name
    assert result["dry_run"] is True, name
    assert result["dispatch_performed"] is False, name
    assert result["model_routing"]["model_call_required"] is False, name
    assert result["safety"]["allowed_to_dispatch"] is False, name
    assert result["confirmation_policy"]["eligible_for_dispatch"] is False, name
    assert result["decision_trace"][0]["step"] == "normalize_input", name
    assert result["decision_trace"][-1]["step"] == "rule_result", name
    assert "router_lookup" in result, name
    assert result["router_lookup"]["dispatch_performed"] is False, name
    assert result["router_lookup"]["model_call_required"] is False, name

print("OK: Stage 6AF local schema compatibility check passed")
PY2

echo
echo "=== existing Stage 6AE lookup helper smoke must still pass ==="
bash ops/smoke/check-stage-6ae-universal-intent-router-sqlite-lookup-helpers.sh

echo
echo "=== verify dry-run router endpoint remains disabled by default ==="
router_code="$(curl -sS --max-time 10 -o /tmp/stage6af-router-disabled.out \
  -w "%{http_code}" \
  -X POST http://127.0.0.1:7070/api/router/dry-run \
  -H 'Content-Type: application/json' \
  --data '{"input":{"text":"next","source":"study","surface":"study_session"},"context":{"active_page":"study"}}' || true)"
echo "router_dry_run_code=$router_code"
cat /tmp/stage6af-router-disabled.out || true
echo

if [ "$router_code" != "404" ]; then
  echo "FAIL: router dry-run endpoint should remain disabled by default"
  exit 1
fi

echo
echo "PASS: Stage 6AF DB-backed dry-run router lookup smoke passed"
