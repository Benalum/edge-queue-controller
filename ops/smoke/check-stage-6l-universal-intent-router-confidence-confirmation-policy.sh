#!/usr/bin/env bash
set -euo pipefail

echo "=== Stage 6L Universal Intent Router confidence and confirmation policy smoke ==="

fail=0

for f in \
  edge_intent_router.py \
  edge_controller.py \
  docs/stage-6l-universal-intent-router-confidence-confirmation-policy.md \
  docs/generated/stage-6h-router-fixtures.json \
  docs/generated/stage-6i-router-alias-fixtures.json
do
  [ -s "$f" ] && echo "OK: $f" || { echo "FAIL: missing $f"; fail=1; }
done

python3 -m py_compile edge_intent_router.py edge_controller.py

grep -q "def _stage6f_confidence_band" edge_intent_router.py && echo "OK: confidence band helper present" || { echo "FAIL: missing confidence band helper"; fail=1; }
grep -q "def _stage6f_confirmation_policy" edge_intent_router.py && echo "OK: confirmation policy helper present" || { echo "FAIL: missing confirmation policy helper"; fail=1; }
grep -q '"confirmation_policy": confirmation_policy' edge_intent_router.py && echo "OK: confirmation policy returned" || { echo "FAIL: confirmation policy not returned"; fail=1; }

.venv/bin/python - <<'PY'
import json
from pathlib import Path

import edge_controller
import edge_intent_router

assert edge_controller._stage6f_router_response is edge_intent_router._stage6f_router_response

fixture_files = [
    Path("docs/generated/stage-6h-router-fixtures.json"),
    Path("docs/generated/stage-6i-router-alias-fixtures.json"),
]

expected_bands = {
    "study.next": "high",
    "study.skip": "high",
    "study.hint": "high",
    "study.answer": "medium",
    "companion.chat": "medium",
    "unknown.general_chat": "low",
    "unknown.unsupported": "none",
}

for fixture_file in fixture_files:
    fixtures = json.loads(fixture_file.read_text())

    for item in fixtures:
        name = item["name"]
        result = edge_controller._stage6f_router_response(item["body"])
        expect = item["expect"]

        intent = result["intent"]["name"]
        expected_band = expected_bands[intent]

        assert result["ok"] is True, name
        assert result["dry_run"] is True, name
        assert result["dispatch_performed"] is False, name
        assert result["model_routing"]["model_call_required"] is False, name
        assert result["safety"]["allowed_to_dispatch"] is False, name

        assert intent == expect["intent"], name
        assert result["intent"]["confidence_band"] == expected_band, name

        policy = result.get("confirmation_policy")
        assert isinstance(policy, dict), name
        assert policy["requires_confirmation"] is False, name
        assert policy["eligible_for_dispatch"] is False, name
        assert policy["dispatch_disabled_reason"] == "dry_run_endpoint_never_dispatches", name
        assert policy["confidence_band"] == expected_band, name

        trace = result["decision_trace"]
        assert trace[-1]["confidence_band"] == expected_band, name
        assert trace[-1]["confidence"] == result["intent"]["confidence"], name

        print(f"OK: {fixture_file.name}: {name} -> {intent} ({expected_band})")

calendar_policy = edge_intent_router._stage6f_confirmation_policy(
    "calendar.write_request",
    "/api/calendar/events",
    0.95,
)

assert calendar_policy["requires_confirmation"] is False
assert calendar_policy["would_require_confirmation_if_dispatch_enabled"] is True
assert calendar_policy["eligible_for_dispatch"] is False

print("OK: future write-intent confirmation policy is represented safely")
PY

if systemctl is-active edge-queue-controller >/dev/null 2>&1; then
  sudo systemctl restart edge-queue-controller
  sleep 3

  code="$(
    curl -sS -o /tmp/stage6l-disabled.json \
      -w "%{http_code}" \
      -X POST http://127.0.0.1:7070/api/router/dry-run \
      -H 'Content-Type: application/json' \
      --data '{"input":{"text":"next card","source":"study","surface":"study_session"},"context":{"active_page":"study"}}' || true
  )"

  echo "disabled_http_code=$code"

  if [ "$code" = "404" ]; then
    echo "OK: endpoint remains disabled by default"
  else
    echo "FAIL: endpoint should still be disabled by default"
    cat /tmp/stage6l-disabled.json || true
    fail=1
  fi
else
  echo "WARN: controller inactive; skipped disabled endpoint check"
fi

if git diff --name-only | grep -E '(^frontend/|^backend/|^public_gateway.py$|^ops/systemd/)' >/dev/null; then
  echo "FAIL: unrelated runtime/systemd files modified"
  git diff --name-only | grep -E '(^frontend/|^backend/|^public_gateway.py$|^ops/systemd/)' || true
  fail=1
else
  echo "OK: no unrelated runtime/systemd files modified"
fi

git status --short

if [ "$fail" -eq 0 ]; then
  echo "PASS: Stage 6L Universal Intent Router confidence and confirmation policy smoke passed"
else
  echo "FAIL: Stage 6L Universal Intent Router confidence and confirmation policy smoke failed"
fi

exit "$fail"
