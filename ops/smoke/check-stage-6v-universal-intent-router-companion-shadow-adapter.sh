#!/usr/bin/env bash
set -euo pipefail

echo "=== Stage 6V Universal Intent Router Companion shadow adapter smoke ==="

fail=0
fixtures="docs/generated/stage-6v-companion-adapter-shadow-fixtures.json"

for f in \
  edge_intent_router.py \
  edge_controller.py \
  "$fixtures" \
  docs/stage-6v-universal-intent-router-companion-shadow-adapter.md \
  docs/stage-6u-universal-intent-router-companion-adapter-plan.md \
  docs/generated/stage-6n-router-response-schema.json
do
  [ -s "$f" ] && echo "OK: $f" || { echo "FAIL: missing $f"; fail=1; }
done

python3 -m json.tool "$fixtures" >/dev/null
python3 -m py_compile edge_intent_router.py edge_controller.py

grep -q "def _stage6v_companion_adapter_shadow" edge_intent_router.py && echo "OK: companion shadow adapter helper present" || { echo "FAIL: companion shadow adapter helper missing"; fail=1; }
grep -q "companion_shadow_dry_run" edge_intent_router.py && echo "OK: companion shadow adapter marker present" || { echo "FAIL: companion shadow adapter marker missing"; fail=1; }

.venv/bin/python - <<'PY'
import json
from pathlib import Path

import edge_intent_router

fixtures = json.loads(Path("docs/generated/stage-6v-companion-adapter-shadow-fixtures.json").read_text())

for item in fixtures:
    name = item["name"]
    result = edge_intent_router._stage6v_companion_adapter_shadow(item["payload"])
    expect = item["expect"]
    router = result["router_result"]

    assert result["ok"] is True, name
    assert result["stage"] == "6V", name
    assert result["adapter"] == "companion_shadow_dry_run", name
    assert result["behavior_changed"] is False, name
    assert result["dispatch_performed"] is False, name
    assert result["model_call_required"] is False, name
    assert result["allowed_to_dispatch"] is False, name
    assert result["errors"] == [], name

    assert router["dry_run"] is True, name
    assert router["dispatch_performed"] is False, name
    assert router["model_routing"]["model_call_required"] is False, name
    assert router["safety"]["allowed_to_dispatch"] is False, name

    assert router["source_surface_policy"]["allowed"] is expect["allowed"], name
    assert router["intent"]["name"] == expect["intent"], name
    assert router["target"]["existing_route"] == expect["route"], name
    assert router["decision_trace"][-1]["rule_id"] == expect["rule_id"], name
    assert router["model_routing"]["tier"] == expect["model_tier"], name

    assert result["shadow_summary"]["intent"] == expect["intent"], name
    assert result["shadow_summary"]["existing_route"] == expect["route"], name
    assert result["shadow_summary"]["rule_id"] == expect["rule_id"], name
    assert result["shadow_summary"]["model_tier"] == expect["model_tier"], name
    assert result["shadow_summary"]["source_surface_allowed"] is expect["allowed"], name

    print(f"OK: {name} -> {expect['intent']}")

print("OK: all Stage 6V Companion shadow adapter fixtures passed")
PY

if systemctl is-active edge-queue-controller >/dev/null 2>&1; then
  sudo systemctl restart edge-queue-controller
  sleep 3

  code="$(
    curl -sS -o /tmp/stage6v-disabled.json \
      -w "%{http_code}" \
      -X POST http://127.0.0.1:7070/api/router/dry-run \
      -H 'Content-Type: application/json' \
      --data '{"input":{"text":"hello","source":"companion","surface":"companion_chat"},"context":{"active_page":"companion"}}' || true
  )"

  echo "disabled_http_code=$code"

  if [ "$code" = "404" ]; then
    echo "OK: endpoint remains disabled by default"
  else
    echo "FAIL: endpoint should still be disabled by default"
    cat /tmp/stage6v-disabled.json || true
    fail=1
  fi
else
  echo "WARN: controller inactive; skipped disabled endpoint check"
fi

if git diff --name-only | grep -E '(^edge_controller.py$|^frontend/|^backend/|^public_gateway.py$|^ops/systemd/)' >/dev/null; then
  echo "FAIL: unrelated runtime/systemd files modified"
  git diff --name-only | grep -E '(^edge_controller.py$|^frontend/|^backend/|^public_gateway.py$|^ops/systemd/)' || true
  fail=1
else
  echo "OK: no unrelated runtime/systemd files modified"
fi

git status --short

if [ "$fail" -eq 0 ]; then
  echo "PASS: Stage 6V Universal Intent Router Companion shadow adapter smoke passed"
else
  echo "FAIL: Stage 6V Universal Intent Router Companion shadow adapter smoke failed"
fi

exit "$fail"
