#!/usr/bin/env bash
set -euo pipefail

echo "=== Stage 6M Universal Intent Router source/surface policy smoke ==="

fail=0

fixtures="docs/generated/stage-6m-router-source-surface-policy-fixtures.json"

for f in \
  edge_intent_router.py \
  edge_controller.py \
  "$fixtures" \
  docs/stage-6m-universal-intent-router-source-surface-policy.md \
  docs/generated/stage-6h-router-fixtures.json \
  docs/generated/stage-6i-router-alias-fixtures.json
do
  [ -s "$f" ] && echo "OK: $f" || { echo "FAIL: missing $f"; fail=1; }
done

python3 -m json.tool "$fixtures" >/dev/null
python3 -m py_compile edge_intent_router.py edge_controller.py

grep -q "def _stage6f_source_surface_policy" edge_intent_router.py && echo "OK: source/surface policy helper present" || { echo "FAIL: missing source/surface policy helper"; fail=1; }
grep -q '"source_surface_policy": source_surface_policy' edge_intent_router.py && echo "OK: source/surface policy returned" || { echo "FAIL: source/surface policy not returned"; fail=1; }
grep -q "policy.source_surface.blocked" edge_intent_router.py && echo "OK: blocked policy rule present" || { echo "FAIL: blocked policy rule missing"; fail=1; }

.venv/bin/python - <<'PY'
import json
from pathlib import Path

import edge_controller

fixture_files = [
    Path("docs/generated/stage-6h-router-fixtures.json"),
    Path("docs/generated/stage-6i-router-alias-fixtures.json"),
]

for fixture_file in fixture_files:
    for item in json.loads(fixture_file.read_text()):
        result = edge_controller._stage6f_router_response(item["body"])
        expect = item["expect"]

        assert result["source_surface_policy"]["allowed"] is True, item["name"]
        assert result["intent"]["name"] == expect["intent"], item["name"]
        assert result["target"]["existing_route"] == expect["route"], item["name"]
        assert result["dispatch_performed"] is False, item["name"]
        assert result["model_routing"]["model_call_required"] is False, item["name"]
        assert result["safety"]["allowed_to_dispatch"] is False, item["name"]

        print(f"OK: existing fixture still allowed: {fixture_file.name}: {item['name']}")

for item in json.loads(Path("docs/generated/stage-6m-router-source-surface-policy-fixtures.json").read_text()):
    result = edge_controller._stage6f_router_response(item["body"])
    expect = item["expect"]
    name = item["name"]

    assert result["source_surface_policy"]["allowed"] is expect["allowed"], name
    assert result["intent"]["name"] == expect["intent"], name
    assert result["target"]["existing_route"] == expect["route"], name
    assert result["decision_trace"][-1]["rule_id"] == expect["rule_id"], name
    assert result["dispatch_performed"] is False, name
    assert result["model_routing"]["model_call_required"] is False, name
    assert result["safety"]["allowed_to_dispatch"] is False, name

    print(f"OK: source/surface policy fixture: {name}")

print("OK: Stage 6M source/surface policy checks passed")
PY

if systemctl is-active edge-queue-controller >/dev/null 2>&1; then
  sudo systemctl restart edge-queue-controller
  sleep 3

  code="$(
    curl -sS -o /tmp/stage6m-disabled.json \
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
    cat /tmp/stage6m-disabled.json || true
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
  echo "PASS: Stage 6M Universal Intent Router source/surface policy smoke passed"
else
  echo "FAIL: Stage 6M Universal Intent Router source/surface policy smoke failed"
fi

exit "$fail"
