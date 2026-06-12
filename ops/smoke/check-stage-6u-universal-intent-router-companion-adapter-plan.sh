#!/usr/bin/env bash
set -euo pipefail

echo "=== Stage 6U Universal Intent Router Companion adapter plan smoke ==="

fail=0

plan="docs/generated/stage-6u-companion-router-adapter-plan.json"
doc="docs/stage-6u-universal-intent-router-companion-adapter-plan.md"
classification="docs/generated/stage-6d-route-classification.tsv"

for f in \
  "$plan" \
  "$doc" \
  "$classification" \
  edge_intent_router.py \
  edge_controller.py \
  docs/stage-6n-universal-intent-router-response-schema.md \
  docs/stage-6o-universal-intent-router-http-enabled-schema-smoke.md \
  docs/stage-6t-universal-intent-router-study-shadow-http-probe-plan.md
do
  [ -s "$f" ] && echo "OK: $f" || { echo "FAIL: missing $f"; fail=1; }
done

echo
echo "=== validate Stage 6U plan json ==="
python3 - <<'PY'
import json
from pathlib import Path

data = json.loads(Path("docs/generated/stage-6u-companion-router-adapter-plan.json").read_text())

assert data["stage"] == "6U"
assert data["runtime_behavior_change"] is False
assert data["adapter_scope"] == "companion_only"

routes = {item["route"] for item in data["current_routes"]}
assert "/api/companion/chat" in routes
assert "/api/chat/queued" in routes

intents = set(data["initial_supported_intents"])
assert "companion.chat" in intents
assert "unknown.general_chat" in intents

for invariant in [
    "never dispatch during Stage 6U",
    "never call a model during Stage 6U",
    "preserve existing Companion behavior",
    "preserve existing queued chat behavior"
]:
    assert invariant in data["safety_invariants"]

requirements = data["future_adapter_contract"]["router_requirements"]
assert requirements["dry_run"] is True
assert requirements["dispatch_performed"] is False
assert requirements["allowed_to_dispatch"] is False
assert requirements["source_surface_policy_allowed"] is True

print("OK: Stage 6U Companion adapter JSON plan is valid")
PY

python3 -m py_compile edge_intent_router.py edge_controller.py

echo
echo "=== verify Companion routes are still known router candidates ==="
for route in \
  "/api/companion/chat" \
  "/api/chat/queued"
do
  if grep -q "$route" "$classification"; then
    echo "OK: route present in classification: $route"
  else
    echo "FAIL: route missing from classification: $route"
    fail=1
  fi
done

echo
echo "=== required doc markers ==="
for marker in \
  "This stage is docs-only" \
  "This stage does not change runtime behavior" \
  "Current Companion router candidates" \
  "Adapter boundary" \
  "Never route through Companion adapter" \
  "Stage 6U does not wire the router into Companion" \
  "Stage 6U does not enable dispatch" \
  "Stage 6U does not enable model calls"
do
  if grep -q "$marker" "$doc"; then
    echo "OK: marker: $marker"
  else
    echo "FAIL: missing marker: $marker"
    fail=1
  fi
done

echo
echo "=== router endpoint should remain disabled by default ==="
if systemctl is-active edge-queue-controller >/dev/null 2>&1; then
  code="$(
    curl -sS -o /tmp/stage6u-router-disabled.json \
      -w "%{http_code}" \
      -X POST http://127.0.0.1:7070/api/router/dry-run \
      -H 'Content-Type: application/json' \
      --data '{"input":{"text":"hello","source":"companion","surface":"companion_chat"},"context":{"active_page":"companion"}}' || true
  )"

  echo "router_disabled_http_code=$code"

  if [ "$code" = "404" ]; then
    echo "OK: router endpoint remains disabled by default"
  else
    echo "FAIL: router endpoint should still be disabled by default"
    cat /tmp/stage6u-router-disabled.json || true
    fail=1
  fi
else
  echo "WARN: controller inactive; skipped router disabled check"
fi

echo
echo "=== no runtime/systemd files should be modified ==="
if git diff --name-only | grep -E '(^edge_controller.py$|^edge_intent_router.py$|^frontend/|^backend/|^public_gateway.py$|^ops/systemd/)' >/dev/null; then
  echo "FAIL: runtime/systemd files modified"
  git diff --name-only | grep -E '(^edge_controller.py$|^edge_intent_router.py$|^frontend/|^backend/|^public_gateway.py$|^ops/systemd/)' || true
  fail=1
else
  echo "OK: no runtime/systemd file modifications detected"
fi

git status --short

if [ "$fail" -eq 0 ]; then
  echo "PASS: Stage 6U Universal Intent Router Companion adapter plan smoke passed"
else
  echo "FAIL: Stage 6U Universal Intent Router Companion adapter plan smoke failed"
fi

exit "$fail"
