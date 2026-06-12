#!/usr/bin/env bash
set -euo pipefail

echo "=== Stage 6N Universal Intent Router response schema smoke ==="

fail=0

schema="docs/generated/stage-6n-router-response-schema.json"

for f in \
  edge_intent_router.py \
  edge_controller.py \
  "$schema" \
  docs/stage-6n-universal-intent-router-response-schema.md \
  docs/generated/stage-6h-router-fixtures.json \
  docs/generated/stage-6i-router-alias-fixtures.json \
  docs/generated/stage-6m-router-source-surface-policy-fixtures.json
do
  [ -s "$f" ] && echo "OK: $f" || { echo "FAIL: missing $f"; fail=1; }
done

python3 -m json.tool "$schema" >/dev/null
python3 -m py_compile edge_intent_router.py edge_controller.py

.venv/bin/python - <<'PY'
import json
from pathlib import Path

import edge_controller

schema = json.loads(Path("docs/generated/stage-6n-router-response-schema.json").read_text())

fixture_files = [
    Path("docs/generated/stage-6h-router-fixtures.json"),
    Path("docs/generated/stage-6i-router-alias-fixtures.json"),
    Path("docs/generated/stage-6m-router-source-surface-policy-fixtures.json"),
]

required_top = schema["required_top_level"]
required_nested = schema["required_nested"]
required_trace_steps = schema["required_decision_trace_steps"]

def validate_response(name, result):
    missing_top = [key for key in required_top if key not in result]
    assert not missing_top, (name, "missing_top", missing_top)

    for parent, keys in required_nested.items():
        assert isinstance(result[parent], dict), (name, parent, "not_dict")
        missing = [key for key in keys if key not in result[parent]]
        assert not missing, (name, parent, "missing_nested", missing)

    assert isinstance(result["decision_trace"], list), name
    assert len(result["decision_trace"]) >= 2, name
    assert result["decision_trace"][0]["step"] == required_trace_steps[0], name
    assert result["decision_trace"][-1]["step"] == required_trace_steps[-1], name

    assert isinstance(result["actions"], list), name
    assert isinstance(result["errors"], list), name

    assert result["ok"] is True, name
    assert result["dry_run"] is True, name
    assert result["dispatch_performed"] is False, name
    assert result["model_routing"]["model_call_required"] is False, name
    assert result["safety"]["allowed_to_dispatch"] is False, name
    assert result["confirmation_policy"]["eligible_for_dispatch"] is False, name

    assert result["confirmation_policy"]["dispatch_disabled_reason"] == "dry_run_endpoint_never_dispatches", name
    assert result["decision_trace"][-1]["dispatch_blocked_reason"] == "dry_run_endpoint_never_dispatches", name

    assert result["intent"]["confidence_band"] == result["confirmation_policy"]["confidence_band"], name
    assert result["decision_trace"][-1]["confidence_band"] == result["intent"]["confidence_band"], name

for fixture_file in fixture_files:
    fixtures = json.loads(fixture_file.read_text())

    for item in fixtures:
        name = f"{fixture_file.name}:{item['name']}"
        result = edge_controller._stage6f_router_response(item["body"])

        validate_response(name, result)

        expect = item["expect"]
        if "intent" in expect:
            assert result["intent"]["name"] == expect["intent"], name
        if "route" in expect:
            assert result["target"]["existing_route"] == expect["route"], name
        if "allowed" in expect:
            assert result["source_surface_policy"]["allowed"] is expect["allowed"], name
        if "rule_id" in expect:
            assert result["decision_trace"][-1]["rule_id"] == expect["rule_id"], name

        print(f"OK: schema valid: {name}")

print("OK: all Stage 6N schema validations passed")
PY

if systemctl is-active edge-queue-controller >/dev/null 2>&1; then
  sudo systemctl restart edge-queue-controller
  sleep 3

  code="$(
    curl -sS -o /tmp/stage6n-disabled.json \
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
    cat /tmp/stage6n-disabled.json || true
    fail=1
  fi
else
  echo "WARN: controller inactive; skipped disabled endpoint check"
fi

if git diff --name-only | grep -E '(^edge_controller.py$|^edge_intent_router.py$|^frontend/|^backend/|^public_gateway.py$|^ops/systemd/)' >/dev/null; then
  echo "FAIL: runtime/systemd files modified"
  git diff --name-only | grep -E '(^edge_controller.py$|^edge_intent_router.py$|^frontend/|^backend/|^public_gateway.py$|^ops/systemd/)' || true
  fail=1
else
  echo "OK: no runtime/systemd file modifications detected"
fi

git status --short

if [ "$fail" -eq 0 ]; then
  echo "PASS: Stage 6N Universal Intent Router response schema smoke passed"
else
  echo "FAIL: Stage 6N Universal Intent Router response schema smoke failed"
fi

exit "$fail"
