#!/usr/bin/env bash
set -euo pipefail

echo "=== Stage 6AG smoke: DB-backed dry-run router fixtures ==="

PYTHON_BIN="${PYTHON_BIN:-.venv/bin/python}"
if [ ! -x "$PYTHON_BIN" ]; then
  PYTHON_BIN="python3"
fi
echo "Using Python: $PYTHON_BIN"

DOC="docs/stage-6ag-universal-intent-router-db-backed-fixtures.md"
OUT="docs/generated/stage-6ag-db-backed-router-fixtures.json"

test -f "$DOC"
test -f edge_intent_router.py
test -f edge_router_lookup.py
test -f edge_queue.sqlite3

grep -q "Stage 6AG Universal Intent Router DB-Backed Fixtures" "$DOC"
grep -q "does not restart the controller" "$DOC"
grep -q "does not enable the router endpoint by default" "$DOC"
grep -q "does not dispatch" "$DOC"
grep -q "does not call models" "$DOC"

echo
echo "=== compile router modules ==="
"$PYTHON_BIN" -m py_compile \
  edge_intent_router.py \
  edge_router_lookup.py \
  edge_router_schema.py \
  edge_router_seed.py \
  edge_controller.py

echo
echo "=== generate DB-backed router fixtures ==="
"$PYTHON_BIN" - <<'PY'
import json
from pathlib import Path

import edge_intent_router

fixtures = {
    "study_next_en": {
        "body": {
            "input": {"text": "next", "source": "study", "surface": "study_session"},
            "context": {"active_page": "study", "profile_language": "en", "role": "user"},
            "router_options": {"dry_run": True, "allow_dispatch": False, "allow_model_call": False},
        },
        "expected_legacy_intent": "study.next",
        "expected_db_intent": "study.card.next",
    },
    "study_skip_en": {
        "body": {
            "input": {"text": "skip", "source": "study", "surface": "study_session"},
            "context": {"active_page": "study", "profile_language": "en", "role": "user"},
            "router_options": {"dry_run": True, "allow_dispatch": False, "allow_model_call": False},
        },
        "expected_legacy_intent": "study.skip",
        "expected_db_intent": "study.card.skip",
    },
    "study_show_answer_en": {
        "body": {
            "input": {"text": "show answer", "source": "study", "surface": "study_session"},
            "context": {"active_page": "study", "profile_language": "en", "role": "user"},
            "router_options": {"dry_run": True, "allow_dispatch": False, "allow_model_call": False},
        },
        "expected_legacy_intent": "study.answer",
        "expected_db_intent": "study.card.answer",
    },
    "study_next_es": {
        "body": {
            "input": {"text": "siguiente", "source": "study", "surface": "study_session"},
            "context": {"active_page": "study", "profile_language": "es", "role": "user"},
            "router_options": {"dry_run": True, "allow_dispatch": False, "allow_model_call": False},
        },
        "expected_legacy_intent": "study.next",
        "expected_db_intent": "study.card.next",
    },
    "blocked_admin_source": {
        "body": {
            "input": {"text": "next", "source": "admin", "surface": "admin"},
            "context": {"active_page": "admin", "profile_language": "en", "role": "admin"},
            "router_options": {"dry_run": True, "allow_dispatch": False, "allow_model_call": False},
        },
        "expected_legacy_intent": "unknown.unsupported",
        "expected_db_intent": None,
    },
}

output = {
    "stage": "6AG",
    "description": "DB-backed dry-run router fixture outputs.",
    "fixtures": {},
}

for name, fixture in fixtures.items():
    result = edge_intent_router._stage6f_router_response(fixture["body"])
    output["fixtures"][name] = {
        "input": fixture["body"],
        "expected_legacy_intent": fixture["expected_legacy_intent"],
        "expected_db_intent": fixture["expected_db_intent"],
        "result": result,
    }

Path("docs/generated/stage-6ag-db-backed-router-fixtures.json").write_text(
    json.dumps(output, indent=2, sort_keys=True) + "\n"
)

print("wrote docs/generated/stage-6ag-db-backed-router-fixtures.json")
PY

echo
echo "=== validate generated fixtures ==="
"$PYTHON_BIN" - <<'PY'
import json
from pathlib import Path

data = json.loads(Path("docs/generated/stage-6ag-db-backed-router-fixtures.json").read_text())

assert data["stage"] == "6AG"

for name, item in data["fixtures"].items():
    result = item["result"]
    lookup = result["router_lookup"]["sqlite_phrase_lookup"]

    assert result["ok"] is True, name
    assert result["dry_run"] is True, name
    assert result["dispatch_performed"] is False, name
    assert result["model_routing"]["model_call_required"] is False, name
    assert result["safety"]["allowed_to_dispatch"] is False, name
    assert result["confirmation_policy"]["eligible_for_dispatch"] is False, name
    assert result["router_lookup"]["stage"] == "6AF", name
    assert result["router_lookup"]["dispatch_performed"] is False, name
    assert result["router_lookup"]["model_call_required"] is False, name
    assert result["decision_trace"][0]["step"] == "normalize_input", name
    assert any(step["step"] == "sqlite_phrase_lookup" for step in result["decision_trace"]), name
    assert result["decision_trace"][-1]["step"] == "rule_result", name

    assert result["intent"]["name"] == item["expected_legacy_intent"], name

    expected_db_intent = item["expected_db_intent"]
    if expected_db_intent:
        assert lookup["matched"] is True, name
        assert lookup["intent_key"] == expected_db_intent, name
    else:
        assert lookup["matched"] is False, name
        assert lookup["error_code"] == "source_surface_policy_blocked", name

print("OK: Stage 6AG generated fixtures are valid")
PY

echo
echo "=== run Stage 6AF smoke regression ==="
bash ops/smoke/check-stage-6af-universal-intent-router-db-backed-dry-run-lookup.sh

echo
echo "=== verify endpoint remains disabled ==="
router_code="$(curl -sS --max-time 10 -o /tmp/stage6ag-router-disabled.out \
  -w "%{http_code}" \
  -X POST http://127.0.0.1:7070/api/router/dry-run \
  -H 'Content-Type: application/json' \
  --data '{"input":{"text":"next","source":"study","surface":"study_session"},"context":{"active_page":"study"}}' || true)"
echo "router_dry_run_code=$router_code"
cat /tmp/stage6ag-router-disabled.out || true
echo

if [ "$router_code" != "404" ]; then
  echo "FAIL: router dry-run endpoint should remain disabled by default"
  exit 1
fi

echo
echo "PASS: Stage 6AG DB-backed dry-run router fixtures smoke passed"
