#!/usr/bin/env bash
set -euo pipefail

echo "=== Stage 7C authenticated shadow comparison artifact schema smoke ==="

fail=0

schema="docs/generated/stage-7c-authenticated-shadow-comparison-artifact-schema.json"
example="docs/generated/stage-7c-authenticated-shadow-comparison-artifact-example.json"
doc="docs/stage-7c-authenticated-shadow-comparison-artifact-schema.md"
foundation="docs/generated/stage-6z-universal-intent-router-foundation-summary.json"
stage7a="docs/generated/stage-7a-authenticated-study-shadow-comparison-plan.json"
stage7b="docs/generated/stage-7b-authenticated-companion-shadow-comparison-plan.json"
classification="docs/generated/stage-6d-route-classification.tsv"

study_helper="_stage6q_study_adapter_shadow"
companion_helper="_stage6v_companion_adapter_shadow"

for f in \
  "$schema" \
  "$example" \
  "$doc" \
  "$foundation" \
  "$stage7a" \
  "$stage7b" \
  "$classification" \
  edge_intent_router.py \
  edge_controller.py \
  docs/stage-6z-universal-intent-router-foundation-completion.md \
  docs/stage-7a-authenticated-study-shadow-comparison-plan.md \
  docs/stage-7b-authenticated-companion-shadow-comparison-plan.md
do
  [ -s "$f" ] && echo "OK: $f" || { echo "FAIL: missing $f"; fail=1; }
done

echo
echo "=== validate Stage 7C schema and example json ==="
python3 - <<'PY'
import json
from pathlib import Path

schema = json.loads(Path("docs/generated/stage-7c-authenticated-shadow-comparison-artifact-schema.json").read_text())
example = json.loads(Path("docs/generated/stage-7c-authenticated-shadow-comparison-artifact-example.json").read_text())

assert schema["stage"] == "7C"
assert schema["runtime_behavior_change"] is False
assert schema["schema_version"] == "stage-7c-v1"
assert schema["artifact_kind"] == "authenticated_shadow_comparison_result"
assert set(schema["supported_domains"]) == {"study", "companion"}

for field in schema["required_top_level_fields"]:
    assert field in example, f"example missing {field}"

assert example["schema_version"] == schema["schema_version"]
assert example["artifact_kind"] == schema["artifact_kind"]
assert example["runtime_behavior_change"] is False
assert example["domain"] in schema["supported_domains"]

domain = example["domain"]
domain_contract = schema["domain_contracts"][domain]
assert example["current_route_observation"]["route"] in domain_contract["allowed_routes"]
assert example["shadow_observation"]["helper"] == domain_contract["shadow_helper"]
assert example["shadow_observation"]["intent"] in domain_contract["expected_safe_intents"]

shadow = example["shadow_observation"]
for key in schema["field_contract"]["shadow_observation"]["required_false_fields"]:
    assert shadow[key] is False, f"shadow field should be false: {key}"

safety = example["safety_observation"]
required_values = schema["field_contract"]["safety_observation"]["required_values"]
for key, expected in required_values.items():
    assert safety[key] == expected, f"safety {key} expected {expected}, got {safety[key]}"

assert example["test_identity"]["real_user_secret_stored"] is False
assert example["current_route_observation"]["raw_response_stored"] is False
assert example["comparison_result"]["user_visible_regression_detected"] is False

for invariant in [
    "no real user secrets stored",
    "no router dispatch",
    "no router model calls",
    "no runtime route wiring changes",
    "no auth bypass",
]:
    assert invariant in schema["global_safety_invariants"]

print("OK: Stage 7C schema and example are valid")
PY

echo
echo "=== validate Stage 7 prerequisites exist ==="
python3 - <<'PY'
import json
from pathlib import Path

foundation = json.loads(Path("docs/generated/stage-6z-universal-intent-router-foundation-summary.json").read_text())
stage7a = json.loads(Path("docs/generated/stage-7a-authenticated-study-shadow-comparison-plan.json").read_text())
stage7b = json.loads(Path("docs/generated/stage-7b-authenticated-companion-shadow-comparison-plan.json").read_text())

assert foundation["stage"] == "6Z"
assert foundation["foundation_status"] == "ready_for_next_phase"
assert foundation["required_current_state"]["router_endpoint_disabled_by_default"] is True
assert foundation["required_current_state"]["dispatch_enabled"] is False
assert foundation["required_current_state"]["model_calls_enabled"] is False

assert stage7a["stage"] == "7A"
assert stage7a["runtime_behavior_change"] is False
assert stage7b["stage"] == "7B"
assert stage7b["runtime_behavior_change"] is False

print("OK: Stage 6Z, 7A, and 7B prerequisites support Stage 7C")
PY

python3 -m py_compile edge_intent_router.py edge_controller.py

echo
echo "=== verify helpers exist and remain isolated ==="
for helper in "$study_helper" "$companion_helper"; do
  if grep -q "def $helper" edge_intent_router.py; then
    echo "OK: helper exists in edge_intent_router.py: $helper"
  else
    echo "FAIL: helper missing from edge_intent_router.py: $helper"
    fail=1
  fi
done

blocked_hits="$(
  grep -RInE "$study_helper|$companion_helper|authenticated_shadow_comparison_artifact" \
    edge_controller.py \
    frontend \
    backend \
    public_gateway.py \
    ops/systemd 2>/dev/null || true
)"

if [ -n "$blocked_hits" ]; then
  echo "FAIL: helper/schema appears in blocked runtime locations"
  echo "$blocked_hits"
  fail=1
else
  echo "OK: helpers/schema not found in blocked runtime locations"
fi

echo
echo "=== verify comparison routes remain classified ==="
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
echo "=== router endpoint should remain disabled by default ==="
if systemctl is-active edge-queue-controller >/dev/null 2>&1; then
  code="$(
    curl -sS -o /tmp/stage7c-router-disabled.json \
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
    cat /tmp/stage7c-router-disabled.json || true
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
  echo "PASS: Stage 7C authenticated shadow comparison artifact schema smoke passed"
else
  echo "FAIL: Stage 7C authenticated shadow comparison artifact schema smoke failed"
fi

exit "$fail"
