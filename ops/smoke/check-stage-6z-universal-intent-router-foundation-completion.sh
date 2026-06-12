#!/usr/bin/env bash
set -euo pipefail

echo "=== Stage 6Z Universal Intent Router foundation completion smoke ==="

fail=0

summary="docs/generated/stage-6z-universal-intent-router-foundation-summary.json"
doc="docs/stage-6z-universal-intent-router-foundation-completion.md"
classification="docs/generated/stage-6d-route-classification.tsv"

study_helper="_stage6q_study_adapter_shadow"
companion_helper="_stage6v_companion_adapter_shadow"

for f in \
  "$summary" \
  "$doc" \
  "$classification" \
  edge_intent_router.py \
  edge_controller.py \
  docs/generated/stage-6n-router-response-schema.json \
  docs/generated/stage-6y-shadow-adapter-registry-plan.json \
  docs/stage-6y-universal-intent-router-shadow-adapter-registry-plan.md \
  ops/smoke/check-stage-6n-universal-intent-router-response-schema.sh \
  ops/smoke/check-stage-6r-universal-intent-router-study-shadow-no-wire-guard.sh \
  ops/smoke/check-stage-6w-universal-intent-router-companion-shadow-no-wire-guard.sh \
  ops/smoke/check-stage-6y-universal-intent-router-shadow-adapter-registry-plan.sh
do
  [ -s "$f" ] && echo "OK: $f" || { echo "FAIL: missing $f"; fail=1; }
done

echo
echo "=== validate Stage 6Z summary json ==="
python3 - <<'PY'
import json
from pathlib import Path

data = json.loads(Path("docs/generated/stage-6z-universal-intent-router-foundation-summary.json").read_text())

assert data["stage"] == "6Z"
assert data["runtime_behavior_change"] is False
assert data["foundation_status"] == "ready_for_next_phase"

groups = {item["group"]: item for item in data["completed_stage_groups"]}
assert "planning_and_inventory" in groups
assert "dry_run_endpoint_and_schema" in groups
assert "study_shadow_path" in groups
assert "companion_shadow_path" in groups
assert "registry_planning" in groups

state = data["required_current_state"]
assert state["router_endpoint_disabled_by_default"] is True
assert state["expected_router_disabled_http_code"] == 404
assert state["dispatch_enabled"] is False
assert state["model_calls_enabled"] is False
assert state["study_shadow_helper_exists"] is True
assert state["companion_shadow_helper_exists"] is True
assert state["shadow_helpers_wired_into_runtime"] is False

for invariant in [
    "no route is wired to router dispatch",
    "no shadow helper is wired into edge_controller.py",
    "router dry-run endpoint remains disabled by default",
    "no model calls are enabled",
    "no state mutation is enabled",
]:
    assert invariant in data["completion_invariants"]

print("OK: Stage 6Z summary JSON is valid")
PY

python3 -m py_compile edge_intent_router.py edge_controller.py

echo
echo "=== verify shadow helpers exist ==="
for helper in "$study_helper" "$companion_helper"; do
  if grep -q "def $helper" edge_intent_router.py; then
    echo "OK: helper exists in edge_intent_router.py: $helper"
  else
    echo "FAIL: helper missing from edge_intent_router.py: $helper"
    fail=1
  fi
done

echo
echo "=== verify core router candidate routes remain classified ==="
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
echo "=== verify helpers/registry are not wired into blocked runtime locations ==="
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
echo "=== run representative foundation smokes ==="
for smoke in \
  ops/smoke/check-stage-6n-universal-intent-router-response-schema.sh \
  ops/smoke/check-stage-6r-universal-intent-router-study-shadow-no-wire-guard.sh \
  ops/smoke/check-stage-6w-universal-intent-router-companion-shadow-no-wire-guard.sh \
  ops/smoke/check-stage-6y-universal-intent-router-shadow-adapter-registry-plan.sh
do
  echo
  echo "--- running $smoke ---"
  bash "$smoke"
done

echo
echo "=== router endpoint should remain disabled by default after representative smokes ==="
if systemctl is-active edge-queue-controller >/dev/null 2>&1; then
  code="$(
    curl -sS -o /tmp/stage6z-router-disabled.json \
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
    cat /tmp/stage6z-router-disabled.json || true
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
  echo "PASS: Stage 6Z Universal Intent Router foundation completion smoke passed"
else
  echo "FAIL: Stage 6Z Universal Intent Router foundation completion smoke failed"
fi

exit "$fail"
