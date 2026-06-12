#!/usr/bin/env bash
set -euo pipefail

echo "=== Stage 7B authenticated Companion shadow comparison plan smoke ==="

fail=0

plan="docs/generated/stage-7b-authenticated-companion-shadow-comparison-plan.json"
doc="docs/stage-7b-authenticated-companion-shadow-comparison-plan.md"
foundation="docs/generated/stage-6z-universal-intent-router-foundation-summary.json"
stage7a="docs/generated/stage-7a-authenticated-study-shadow-comparison-plan.json"
classification="docs/generated/stage-6d-route-classification.tsv"
companion_helper="_stage6v_companion_adapter_shadow"

for f in \
  "$plan" \
  "$doc" \
  "$foundation" \
  "$stage7a" \
  "$classification" \
  edge_intent_router.py \
  edge_controller.py \
  docs/stage-6z-universal-intent-router-foundation-completion.md \
  docs/stage-6u-universal-intent-router-companion-adapter-plan.md \
  docs/stage-6v-universal-intent-router-companion-shadow-adapter.md \
  docs/stage-6w-universal-intent-router-companion-shadow-no-wire-guard.md \
  docs/stage-6x-universal-intent-router-companion-route-baseline.md \
  docs/stage-7a-authenticated-study-shadow-comparison-plan.md
do
  [ -s "$f" ] && echo "OK: $f" || { echo "FAIL: missing $f"; fail=1; }
done

echo
echo "=== validate Stage 7B plan json ==="
python3 - <<'PY'
import json
from pathlib import Path

data = json.loads(Path("docs/generated/stage-7b-authenticated-companion-shadow-comparison-plan.json").read_text())

assert data["stage"] == "7B"
assert data["runtime_behavior_change"] is False
assert data["phase"] == "authenticated_shadow_comparison_planning"

foundation = data["foundation_required"]
assert foundation["stage_6z_complete"] is True
assert foundation["stage_7a_complete"] is True
assert foundation["router_foundation_status"] == "ready_for_next_phase"
assert foundation["router_endpoint_disabled_by_default"] is True
assert foundation["expected_router_disabled_http_code"] == 404
assert foundation["companion_shadow_helper"] == "_stage6v_companion_adapter_shadow"
assert foundation["companion_shadow_helper_wired_into_runtime"] is False

routes = {item["route"] for item in data["companion_routes_under_comparison"]}
assert "/api/companion/chat" in routes
assert "/api/chat/queued" in routes

expected_intents = {item["expected_shadow_intent"] for item in data["future_authenticated_inputs"]}
assert expected_intents == {"companion.chat"}

for rule in [
    "do not bypass authentication",
    "do not store real user secrets in docs or fixtures",
    "do not enable router dispatch",
    "do not enable router model calls",
    "do not wire the Companion shadow helper into edge_controller.py",
    "do not write Calendar entries",
    "do not mutate Profile preferences",
]:
    assert rule in data["safety_rules"]

print("OK: Stage 7B plan JSON is valid")
PY

echo
echo "=== validate Stage 6Z and Stage 7A prerequisites ==="
python3 - <<'PY'
import json
from pathlib import Path

foundation = json.loads(Path("docs/generated/stage-6z-universal-intent-router-foundation-summary.json").read_text())
stage7a = json.loads(Path("docs/generated/stage-7a-authenticated-study-shadow-comparison-plan.json").read_text())

assert foundation["stage"] == "6Z"
assert foundation["foundation_status"] == "ready_for_next_phase"
assert foundation["required_current_state"]["router_endpoint_disabled_by_default"] is True
assert foundation["required_current_state"]["expected_router_disabled_http_code"] == 404
assert foundation["required_current_state"]["dispatch_enabled"] is False
assert foundation["required_current_state"]["model_calls_enabled"] is False
assert foundation["required_current_state"]["companion_shadow_helper_exists"] is True
assert foundation["required_current_state"]["shadow_helpers_wired_into_runtime"] is False

assert stage7a["stage"] == "7A"
assert stage7a["runtime_behavior_change"] is False
assert stage7a["foundation_required"]["stage_6z_complete"] is True

print("OK: Stage 6Z and Stage 7A prerequisites support Stage 7B")
PY

python3 -m py_compile edge_intent_router.py edge_controller.py

echo
echo "=== verify Companion helper exists and remains isolated ==="
if grep -q "def $companion_helper" edge_intent_router.py; then
  echo "OK: helper exists in edge_intent_router.py: $companion_helper"
else
  echo "FAIL: helper missing from edge_intent_router.py: $companion_helper"
  fail=1
fi

blocked_hits="$(
  grep -RIn "$companion_helper" \
    edge_controller.py \
    frontend \
    backend \
    public_gateway.py \
    ops/systemd 2>/dev/null || true
)"

if [ -n "$blocked_hits" ]; then
  echo "FAIL: Companion helper appears in blocked runtime locations"
  echo "$blocked_hits"
  fail=1
else
  echo "OK: Companion helper not wired into blocked runtime locations"
fi

echo
echo "=== verify Companion/Chat routes remain classified ==="
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
echo "=== verify Companion shadow helper output for safe examples ==="
.venv/bin/python - <<'PY'
import edge_intent_router

examples = [
    {"message": "Can you help me plan my study time?"},
    {"text": "What should I work on next?", "source": "chat", "surface": "chat_box", "active_page": "chat"},
    {"prompt": "Help me organize my next step."},
]

for payload in examples:
    result = edge_intent_router._stage6v_companion_adapter_shadow(payload)
    router = result["router_result"]

    assert result["stage"] == "6V"
    assert result["adapter"] == "companion_shadow_dry_run"
    assert result["behavior_changed"] is False
    assert result["dispatch_performed"] is False
    assert result["model_call_required"] is False
    assert result["allowed_to_dispatch"] is False

    assert router["dry_run"] is True
    assert router["intent"]["name"] == "companion.chat"
    assert router["target"]["existing_route"] == "/api/companion/chat"
    assert router["model_routing"]["model_call_required"] is False
    assert router["safety"]["allowed_to_dispatch"] is False
    assert router["dispatch_performed"] is False

    print(f"OK: companion shadow example -> {router['intent']['name']} rule={router['decision_trace'][-1]['rule_id']}")

print("OK: Companion shadow examples remain dry-run-only")
PY

echo
echo "=== verify unauthenticated Companion/Chat routes remain auth-protected ==="
if systemctl is-active edge-queue-controller >/dev/null 2>&1; then
  for route in \
    "/api/companion/chat" \
    "/api/chat/queued"
  do
    out="/tmp/stage7b$(echo "$route" | tr '/' '_').json"
    code="$(
      curl -sS -o "$out" \
        -w "%{http_code}" \
        -X POST "http://127.0.0.1:7070$route" \
        -H 'Content-Type: application/json' \
        --data '{}' || true
    )"

    echo "companion_unauth_probe route=$route http_code=$code"

    if [ "$code" = "401" ]; then
      echo "OK: Companion/Chat route remains auth-protected: $route"
    else
      echo "FAIL: expected Companion/Chat route to remain auth-protected with 401: $route"
      cat "$out" || true
      fail=1
    fi
  done
else
  echo "WARN: controller inactive; skipped unauthenticated Companion/Chat route check"
fi

echo
echo "=== router endpoint should remain disabled by default ==="
if systemctl is-active edge-queue-controller >/dev/null 2>&1; then
  code="$(
    curl -sS -o /tmp/stage7b-router-disabled.json \
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
    cat /tmp/stage7b-router-disabled.json || true
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
  echo "PASS: Stage 7B authenticated Companion shadow comparison plan smoke passed"
else
  echo "FAIL: Stage 7B authenticated Companion shadow comparison plan smoke failed"
fi

exit "$fail"
