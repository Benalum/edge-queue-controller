#!/usr/bin/env bash
set -euo pipefail

echo "=== Stage 6J Universal Intent Router helper module smoke ==="

fail=0

for f in \
  edge_controller.py \
  edge_intent_router.py \
  docs/stage-6j-universal-intent-router-helper-module.md \
  docs/generated/stage-6h-router-fixtures.json \
  docs/generated/stage-6i-router-alias-fixtures.json
do
  if [ -s "$f" ]; then
    echo "OK: $f"
  else
    echo "FAIL: missing $f"
    fail=1
  fi
done

echo
echo "=== syntax check ==="
python3 -m py_compile edge_controller.py edge_intent_router.py

echo
echo "=== module checks ==="
grep -q "from edge_intent_router import" edge_controller.py && echo "OK: controller imports helper module" || { echo "FAIL: missing helper import"; fail=1; }
grep -q "def _stage6f_router_response" edge_intent_router.py && echo "OK: response helper in module" || { echo "FAIL: response helper missing"; fail=1; }
grep -q "def _stage6f_router_enabled" edge_intent_router.py && echo "OK: enabled helper in module" || { echo "FAIL: enabled helper missing"; fail=1; }

echo
echo "=== compatibility and fixture checks ==="
.venv/bin/python - <<'PY'
import json
from pathlib import Path

import edge_controller
import edge_intent_router

assert edge_controller._stage6f_router_response is edge_intent_router._stage6f_router_response
assert edge_controller._stage6f_router_enabled is edge_intent_router._stage6f_router_enabled

fixture_files = [
    Path("docs/generated/stage-6h-router-fixtures.json"),
    Path("docs/generated/stage-6i-router-alias-fixtures.json"),
]

for fixture_file in fixture_files:
    fixtures = json.loads(fixture_file.read_text())

    for item in fixtures:
        name = item["name"]
        result = edge_controller._stage6f_router_response(item["body"])
        expect = item["expect"]

        assert result["ok"] is True, name
        assert result["dry_run"] is True, name
        assert result["dispatch_performed"] is False, name
        assert result["model_routing"]["model_call_required"] is False, name
        assert result["safety"]["allowed_to_dispatch"] is False, name
        assert result["intent"]["name"] == expect["intent"], (name, result["intent"]["name"], expect["intent"])
        assert result["language"]["detected"] == expect["language"], (name, result["language"]["detected"], expect["language"])
        assert result["target"]["existing_route"] == expect["route"], (name, result["target"]["existing_route"], expect["route"])
        assert result["model_routing"]["tier"] == expect["tier"], (name, result["model_routing"]["tier"], expect["tier"])

        print(f"OK: {fixture_file.name}: {name} -> {expect['intent']}")

print("OK: Stage 6J compatibility and fixture checks passed")
PY

echo
echo "=== endpoint must remain disabled by default ==="
if systemctl is-active edge-queue-controller >/dev/null 2>&1; then
  sudo systemctl restart edge-queue-controller
  sleep 3

  code="$(
    curl -sS -o /tmp/stage6j-disabled.json \
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
    cat /tmp/stage6j-disabled.json || true
    fail=1
  fi
else
  echo "WARN: controller inactive; skipped disabled endpoint check"
fi

echo
echo "=== unrelated files check ==="
if git diff --name-only | grep -E '(^frontend/|^backend/|^public_gateway.py$|^ops/systemd/)' >/dev/null; then
  echo "FAIL: unrelated runtime/systemd files modified"
  git diff --name-only | grep -E '(^frontend/|^backend/|^public_gateway.py$|^ops/systemd/)' || true
  fail=1
else
  echo "OK: no unrelated runtime/systemd files modified"
fi

git status --short

if [ "$fail" -eq 0 ]; then
  echo "PASS: Stage 6J Universal Intent Router helper module smoke passed"
else
  echo "FAIL: Stage 6J Universal Intent Router helper module smoke failed"
fi

exit "$fail"
