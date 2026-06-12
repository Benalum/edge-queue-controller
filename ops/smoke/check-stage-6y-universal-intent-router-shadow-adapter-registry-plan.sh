#!/usr/bin/env bash
set -euo pipefail

echo "=== Stage 6Y Universal Intent Router shadow adapter registry plan smoke ==="

fail=0

plan="docs/generated/stage-6y-shadow-adapter-registry-plan.json"
doc="docs/stage-6y-universal-intent-router-shadow-adapter-registry-plan.md"
classification="docs/generated/stage-6d-route-classification.tsv"

study_helper="_stage6q_study_adapter_shadow"
companion_helper="_stage6v_companion_adapter_shadow"

for f in \
  "$plan" \
  "$doc" \
  "$classification" \
  edge_intent_router.py \
  edge_controller.py \
  docs/stage-6p-universal-intent-router-study-adapter-plan.md \
  docs/stage-6q-universal-intent-router-study-shadow-adapter.md \
  docs/stage-6r-universal-intent-router-study-shadow-no-wire-guard.md \
  docs/stage-6s-universal-intent-router-study-route-baseline.md \
  docs/stage-6t-universal-intent-router-study-shadow-http-probe-plan.md \
  docs/stage-6u-universal-intent-router-companion-adapter-plan.md \
  docs/stage-6v-universal-intent-router-companion-shadow-adapter.md \
  docs/stage-6w-universal-intent-router-companion-shadow-no-wire-guard.md \
  docs/stage-6x-universal-intent-router-companion-route-baseline.md
do
  [ -s "$f" ] && echo "OK: $f" || { echo "FAIL: missing $f"; fail=1; }
done

echo
echo "=== validate Stage 6Y registry plan json ==="
python3 - <<'PY'
import json
from pathlib import Path

data = json.loads(Path("docs/generated/stage-6y-shadow-adapter-registry-plan.json").read_text())

assert data["stage"] == "6Y"
assert data["runtime_behavior_change"] is False
assert data["registry_scope"] == "shadow_adapters_only"

adapters = {item["adapter_id"]: item for item in data["adapters"]}
assert set(adapters) == {"study", "companion"}

study = adapters["study"]
assert study["helper"] == "_stage6q_study_adapter_shadow"
assert study["allowed_file"] == "edge_intent_router.py"
assert study["wired_into_runtime"] is False
assert "/api/study/intent/parse" in study["router_candidate_routes"]
assert "/api/study/session/command" in study["router_candidate_routes"]

companion = adapters["companion"]
assert companion["helper"] == "_stage6v_companion_adapter_shadow"
assert companion["allowed_file"] == "edge_intent_router.py"
assert companion["wired_into_runtime"] is False
assert "/api/companion/chat" in companion["router_candidate_routes"]
assert "/api/chat/queued" in companion["router_candidate_routes"]

requirements = data["future_registry_requirements"]
assert requirements["single_lookup_by_adapter_id"] is True
assert requirements["helper_must_remain_dry_run_until_explicit_wiring_stage"] is True
assert requirements["dispatch_enabled_by_default"] is False
assert requirements["model_calls_enabled_by_default"] is False
assert requirements["source_surface_policy_required"] is True
assert requirements["confirmation_policy_required"] is True
assert requirements["decision_trace_required"] is True

for required in [
    "do not wire registry into edge_controller.py during Stage 6Y",
    "do not expose registry through an HTTP endpoint during Stage 6Y",
    "do not enable router dispatch during Stage 6Y",
    "do not enable model calls during Stage 6Y",
]:
    assert required in data["must_not_do"]

print("OK: Stage 6Y registry plan JSON is valid")
PY

python3 -m py_compile edge_intent_router.py edge_controller.py

echo
echo "=== verify adapter helpers exist ==="
for helper in "$study_helper" "$companion_helper"; do
  if grep -q "def $helper" edge_intent_router.py; then
    echo "OK: helper exists in edge_intent_router.py: $helper"
  else
    echo "FAIL: helper missing from edge_intent_router.py: $helper"
    fail=1
  fi
done

echo
echo "=== verify all registry routes remain classified ==="
for route in \
  "/api/study/intent/parse" \
  "/api/study/session/command" \
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
echo "=== verify helpers are not wired into blocked runtime locations ==="
blocked_hits="$(
  grep -RInE "$study_helper|$companion_helper|shadow_adapter_registry" \
    edge_controller.py \
    frontend \
    backend \
    public_gateway.py \
    ops/systemd 2>/dev/null || true
)"

if [ -n "$blocked_hits" ]; then
  echo "FAIL: helper or registry appears in blocked runtime locations"
  echo "$blocked_hits"
  fail=1
else
  echo "OK: helpers/registry not found in blocked runtime locations"
fi

echo
echo "=== router endpoint should remain disabled by default ==="
if systemctl is-active edge-queue-controller >/dev/null 2>&1; then
  code="$(
    curl -sS -o /tmp/stage6y-router-disabled.json \
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
    cat /tmp/stage6y-router-disabled.json || true
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
  echo "PASS: Stage 6Y Universal Intent Router shadow adapter registry plan smoke passed"
else
  echo "FAIL: Stage 6Y Universal Intent Router shadow adapter registry plan smoke failed"
fi

exit "$fail"
